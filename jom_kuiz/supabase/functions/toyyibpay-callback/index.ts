/**
 * Edge Function: toyyibpay-callback
 *
 * Receives the POST callback from ToyyibPay after a payment attempt.
 * ToyyibPay posts form-encoded data to this URL.
 *
 * Flow:
 *   1. Parse callback payload.
 *   2. Verify payment status with ToyyibPay getBillTransactions API.
 *   3. Update payment_transactions row.
 *   4. If successful → call activate_subscription RPC.
 *
 * This function uses service_role so it can write without user auth.
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

const TOYYIBPAY_SECRET_KEY = Deno.env.get('TOYYIBPAY_SECRET_KEY')!;
const TOYYIBPAY_BASE_URL   = Deno.env.get('TOYYIBPAY_BASE_URL') ?? 'https://toyyibpay.com';
const SUPABASE_URL         = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // ── 1. Parse ToyyibPay callback payload ───────────────────────────────
    // ToyyibPay sends a form-encoded POST: refno, status, billcode, etc.
    let billCode: string | undefined;
    let callbackStatus: string | undefined; // '1' = success, '2' = pending, '3' = failed

    const contentType = req.headers.get('content-type') ?? '';
    if (contentType.includes('application/x-www-form-urlencoded')) {
      const text = await req.text();
      const params = new URLSearchParams(text);
      billCode       = params.get('billcode') ?? params.get('billCode') ?? undefined;
      callbackStatus = params.get('status_id') ?? params.get('status') ?? undefined;
    } else {
      const json = await req.json().catch(() => ({}));
      billCode       = json.billcode ?? json.billCode;
      callbackStatus = json.status_id ?? json.status;
    }

    if (!billCode) {
      return new Response('Missing bill code', { status: 400 });
    }

    // ── 2. Verify directly with ToyyibPay (never trust callback status) ────
    const verifiedStatus = await verifyWithToyyibPay(billCode);

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

    // ── 3. Fetch our transaction record ────────────────────────────────────
    const { data: txRow, error: txErr } = await supabase
      .from('payment_transactions')
      .select('*')
      .eq('bill_code', billCode)
      .single();

    if (txErr || !txRow) {
      console.error('Transaction not found for bill_code:', billCode);
      return new Response('Transaction not found', { status: 404 });
    }

    // Idempotency: skip if already processed.
    if (txRow.status !== 'pending') {
      return new Response('Already processed', { status: 200 });
    }

    // ── 4. Update transaction status ───────────────────────────────────────
    const updateFields: Record<string, unknown> = {
      status:     verifiedStatus.status,
      updated_at: new Date().toISOString(),
    };
    if (verifiedStatus.transactionId) {
      updateFields.transaction_id  = verifiedStatus.transactionId;
    }
    if (verifiedStatus.paymentMethod) {
      updateFields.payment_method  = verifiedStatus.paymentMethod;
    }
    if (verifiedStatus.status === 'success') {
      updateFields.paid_at         = new Date().toISOString();
    }

    const { error: updateErr } = await supabase
      .from('payment_transactions')
      .update(updateFields)
      .eq('id', txRow.id);

    if (updateErr) {
      console.error('Failed to update transaction:', updateErr);
      return new Response('DB update failed', { status: 500 });
    }

    // ── 5. Activate subscription on success ────────────────────────────────
    if (verifiedStatus.status === 'success') {
      const { error: rpcErr } = await supabase.rpc('activate_subscription', {
        p_parent_id:  txRow.parent_id,
        p_package_id: txRow.package_id,
      });
      if (rpcErr) {
        // Log but do not fail the callback — the cron/verify function will retry.
        console.error('activate_subscription RPC failed:', rpcErr);
      }
    }

    return new Response('OK', { status: 200 });

  } catch (err) {
    console.error('Unhandled error in toyyibpay-callback:', err);
    return new Response('Internal server error', { status: 500 });
  }
});

// ── ToyyibPay getBillTransactions ─────────────────────────────────────────────

interface VerificationResult {
  status: 'success' | 'failed' | 'pending' | 'expired';
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
      `&billpaymentStatus=1`; // 1 = successful only

    const res = await fetch(url);
    if (!res.ok) {
      console.error('ToyyibPay getBillTransactions HTTP error', res.status);
      return { status: 'failed' };
    }

    const data = await res.json();
    if (!Array.isArray(data) || data.length === 0) {
      // No successful transactions — either pending or failed.
      return { status: 'pending' };
    }

    const tx = data[0];
    return {
      status:        'success',
      transactionId: tx.billpaymentInvoiceNo ?? tx.transactionId,
      paymentMethod: tx.billpaymentChannel ?? tx.paymentChannel,
    };
  } catch (err) {
    console.error('verifyWithToyyibPay error:', err);
    return { status: 'failed' };
  }
}
