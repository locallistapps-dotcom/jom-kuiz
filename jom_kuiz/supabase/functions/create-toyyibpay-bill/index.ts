/**
 * Edge Function: create-toyyibpay-bill
 *
 * Called by the Flutter app when a parent taps "Subscribe".
 * Creates a ToyyibPay bill, stores a pending payment_transactions row,
 * and returns the bill code + payment URL.
 *
 * Required Supabase secrets (set via `supabase secrets set`):
 *   TOYYIBPAY_SECRET_KEY      — your ToyyibPay userSecretKey
 *   TOYYIBPAY_CATEGORY_CODE   — your ToyyibPay category code
 *   TOYYIBPAY_BASE_URL        — https://toyyibpay.com (prod) or https://dev.toyyibpay.com (sandbox)
 *   TOYYIBPAY_CALLBACK_URL    — public URL of the toyyibpay-callback edge function
 *   SUPABASE_URL              — auto-injected by Supabase
 *   SUPABASE_SERVICE_ROLE_KEY — auto-injected by Supabase
 */

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const TOYYIBPAY_SECRET_KEY    = Deno.env.get('TOYYIBPAY_SECRET_KEY')!;
const TOYYIBPAY_CATEGORY_CODE = Deno.env.get('TOYYIBPAY_CATEGORY_CODE')!;
const TOYYIBPAY_BASE_URL      = Deno.env.get('TOYYIBPAY_BASE_URL') ?? 'https://toyyibpay.com';
const TOYYIBPAY_CALLBACK_URL  = Deno.env.get('TOYYIBPAY_CALLBACK_URL')!;
const SUPABASE_URL            = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_KEY    = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

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

    // ── 2. Parse + validate body ───────────────────────────────────────────
    const body = await req.json();
    const { parent_id, package_id, amount, parent_name, parent_email, package_name, package_description } = body;

    if (!parent_id || !package_id || !amount || !parent_email) {
      return errorResponse('Missing required fields', 400);
    }

    // Verify the caller owns this parent record.
    const { data: parentRow, error: parentErr } = await supabase
      .from('parents')
      .select('id')
      .eq('id', parent_id)
      .eq('user_id', user.id)
      .single();

    if (parentErr || !parentRow) {
      return errorResponse('Parent not found or not owned by caller', 403);
    }

    // ── 3. Call ToyyibPay createBill ───────────────────────────────────────
    const billDescription = package_description ?? `Jom Kuiz – ${package_name}`;
    const returnUrl = `${SUPABASE_URL}/functions/v1/toyyibpay-callback?source=return`;

    const formData = new URLSearchParams({
      userSecretKey:          TOYYIBPAY_SECRET_KEY,
      categoryCode:           TOYYIBPAY_CATEGORY_CODE,
      billName:               `JomKuiz_${package_name}`.substring(0, 30),
      billDescription:        billDescription.substring(0, 100),
      billPriceSetting:       '1',         // fixed price
      billPayorInfo:          '1',
      billAmount:             String(amount), // in sen
      billReturnUrl:          returnUrl,
      billCallbackUrl:        TOYYIBPAY_CALLBACK_URL,
      billExternalReferenceNo: `${parent_id.substring(0,8)}_${Date.now()}`,
      billTo:                 parent_name ?? 'Parent',
      billEmail:              parent_email,
      billPhone:              '',
      billSplitPayment:       '0',
      billSplitPaymentArgs:   '',
      billPaymentChannel:     '0',         // all channels (FPX + eWallet)
      billContentEmail:       `Thank you for subscribing to ${package_name} on Jom Kuiz!`,
      billChargeToCustomer:   '1',
    });

    const tpRes = await fetch(`${TOYYIBPAY_BASE_URL}/index.php/api/createBill`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: formData.toString(),
    });

    if (!tpRes.ok) {
      console.error('ToyyibPay createBill HTTP error', tpRes.status);
      return errorResponse('ToyyibPay service unavailable', 502);
    }

    const tpJson = await tpRes.json();
    // ToyyibPay returns [{"BillCode":"abc123"}] on success
    const billCode: string | undefined = Array.isArray(tpJson)
      ? tpJson[0]?.BillCode
      : tpJson?.BillCode;

    if (!billCode) {
      console.error('Unexpected ToyyibPay response', JSON.stringify(tpJson));
      return errorResponse('ToyyibPay did not return a bill code', 502);
    }

    // ── 4. Store pending transaction ───────────────────────────────────────
    const { data: txRow, error: insertErr } = await supabase
      .from('payment_transactions')
      .insert({
        parent_id:  parent_id,
        package_id: package_id,
        bill_code:  billCode,
        amount:     amount,
        status:     'pending',
      })
      .select()
      .single();

    if (insertErr) {
      console.error('DB insert error', insertErr);
      return errorResponse('Failed to store transaction record', 500);
    }

    // ── 5. Return transaction + payment URL ────────────────────────────────
    return new Response(
      JSON.stringify({
        ok:          true,
        transaction: txRow,
        payment_url: `${TOYYIBPAY_BASE_URL}/${billCode}`,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status:  200,
      },
    );

  } catch (err) {
    console.error('Unhandled error in create-toyyibpay-bill:', err);
    return errorResponse('Internal server error', 500);
  }
});

function errorResponse(message: string, status: number): Response {
  return new Response(
    JSON.stringify({ ok: false, error: message }),
    {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status,
    },
  );
}
