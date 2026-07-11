/**
 * Edge Function: verify-toyyibpay-payment
 *
 * Called by the Flutter app when the user taps "I've completed payment"
 * on the checkout screen. Performs a server-side verification with
 * ToyyibPay and activates the subscription if payment was successful.
 *
 * This is idempotent — calling it on an already-processed transaction is safe.
 *
 * Required Supabase secrets:
 *   TOYYIBPAY_SECRET_KEY
 *   TOYYIBPAY_BASE_URL
 *   SUPABASE_URL              (auto-injected)
 *   SUPABASE_SERVICE_ROLE_KEY (auto-injected)
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const TOYYIBPAY_BASE_URL   = Deno.env.get('TOYYIBPAY_BASE_URL') ?? 'https://toyyibpay.com';
const SUPABASE_URL         = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── 1. Authenticate caller ─────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return errorResponse('Missing Authorization header', 401);
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const userClient = createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return errorResponse('Unauthorized', 401);
    }

    // ── 2. Parse body ──────────────────────────────────────────────────────
    const { bill_code: billCode } = await req.json();
    if (!billCode) {
      return errorResponse('bill_code is required', 400);
    }

    // ── 3. Fetch transaction & verify ownership ────────────────────────────
    const { data: txRow, error: txErr } = await supabase
      .from('payment_transactions')
      .select('*, parents!inner(user_id)')
      .eq('bill_code', billCode)
      .single();

    if (txErr || !txRow) {
      return errorResponse('Transaction not found', 404);
    }

    // Ensure the caller owns this transaction.
    if (txRow.parents?.user_id !== user.id) {
      return errorResponse('Forbidden', 403);
    }

    // ── 4. Return immediately if already finalised ─────────────────────────
    if (txRow.status !== 'pending') {
      return successResponse(txRow);
    }

    // ── 5. Verify with ToyyibPay ───────────────────────────────────────────
    const verified = await verifyWithToyyibPay(billCode);

    // ── 6. Update transaction ──────────────────────────────────────────────
    const updateFields: Record<string, unknown> = {
      status:     verified.status,
      updated_at: new Date().toISOString(),
    };
    if (verified.transactionId) updateFields.transaction_id = verified.transactionId;
    if (verified.paymentMethod) updateFields.payment_method = verified.paymentMethod;
    if (verified.status === 'success') updateFields.paid_at = new Date().toISOString();

    const { data: updatedTx, error: updateErr } = await supabase
      .from('payment_transactions')
      .update(updateFields)
      .eq('id', txRow.id)
      .select()
      .single();

    if (updateErr) {
      console.error('DB update error:', updateErr);
      return errorResponse('Failed to update transaction', 500);
    }

    // ── 7. Activate subscription on success ────────────────────────────────
    if (verified.status === 'success') {
      const { error: rpcErr } = await supabase.rpc('activate_subscription', {
        p_parent_id:  txRow.parent_id,
        p_package_id: txRow.package_id,
      });
      if (rpcErr) {
        console.error('activate_subscription RPC error:', rpcErr);
        // Don't fail the verify call — client will see success status and
        // can re-check subscription state on next app load.
      }
    }

    return successResponse(updatedTx);

  } catch (err) {
    console.error('Unhandled error in verify-toyyibpay-payment:', err);
    return errorResponse('Internal server error', 500);
  }
});

// ── Helpers ───────────────────────────────────────────────────────────────────

interface VerificationResult {
  status: 'success' | 'failed' | 'pending';
  transactionId?: string;
  paymentMethod?: string;
}

async function verifyWithToyyibPay(
  billCode: string,
): Promise<VerificationResult> {
  try {
    const url =
      `${TOYYIBPAY_BASE_URL}/index.php/api/getBillTransactions` +
      `?billCode=${encodeURIComponent(billCode)}` +
      `&billpaymentStatus=1`;

    const res = await fetch(url);
    if (!res.ok) return { status: 'pending' };

    const data = await res.json();
    if (!Array.isArray(data) || data.length === 0) {
      return { status: 'pending' };
    }

    const tx = data[0];
    return {
      status:        'success',
      transactionId: tx.billpaymentInvoiceNo ?? tx.transactionId,
      paymentMethod: tx.billpaymentChannel   ?? tx.paymentChannel,
    };
  } catch {
    return { status: 'pending' };
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
function successResponse(tx: Record<string, any>): Response {
  return new Response(
    JSON.stringify({ ok: true, transaction: tx }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status:  200,
    },
  );
}

function errorResponse(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ ok: false, error: message }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status,
    },
  );
}
