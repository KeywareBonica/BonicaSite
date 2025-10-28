import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ success: false, error: 'Method not allowed' }), {
      headers: { 'Content-Type': 'application/json' },
      status: 405,
    });
  }

  try {
    const { email, subject, message } = await req.json();

    if (!email || !subject || !message) {
      return new Response(JSON.stringify({ success: false, error: 'Missing required fields' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 400,
      });
    }

    const apiKey = Deno.env.get('RESEND_API_KEY');
    if (!apiKey) {
      return new Response(JSON.stringify({ success: false, error: 'Server email configuration missing' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 500,
      });
    }

    const fromAddress = Deno.env.get('RESEND_FROM') || 'onboarding@resend.dev';

    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${apiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: fromAddress,
        to: [email],
        subject,
        html: `<div style="font-family: Inter, Arial, sans-serif; line-height:1.6; color:#111827;">
                 ${message}
               </div>`,
      }),
    });

    const data = await resendResponse.json();

    if (!resendResponse.ok) {
      return new Response(JSON.stringify({ success: false, error: data?.message || 'Email provider error' }), {
        headers: { 'Content-Type': 'application/json' },
        status: 502,
      });
    }

    return new Response(JSON.stringify({ success: true, data }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    return new Response(JSON.stringify({ success: false, error: message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});



