const nodemailer = require('nodemailer');
const { db, admin } = require('../config/firebase');

// Reusable core SMTP sender
async function sendHTMLEmail({ toEmail, subject, title, userName, detailsHtml, contactInfo }) {
  const host = process.env.SMTP_HOST || 'smtp.gmail.com';
  const port = parseInt(process.env.SMTP_PORT || '587');
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;
  const from = process.env.SMTP_FROM || 'noreply@echothread.org';

  const hasConfig = user && user !== 'test@gmail.com' && pass && pass !== 'password';

  if (!hasConfig) {
    console.log(`[SIMULATED EMAIL] To: ${toEmail}, Subject: ${subject}`);
    await db.collection('simulated_notifications').add({
      recipient: toEmail,
      name: userName,
      type: 'email',
      title: subject,
      content: `Title: ${title}\nUser: ${userName}\nDetails: ${detailsHtml}\nContact: ${contactInfo}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });
    return;
  }

  try {

  console.log("===== SMTP CONFIG =====");
  console.log("HOST:", process.env.SMTP_HOST);
  console.log("PORT:", process.env.SMTP_PORT);
  console.log("USER:", process.env.SMTP_USER);
  console.log("FROM:", process.env.SMTP_FROM);
  console.log("=======================");

  const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: port,
  secure: port === 465, // Use true for SSL (port 465), false for other ports (like 587 or 2525)
  requireTLS: true,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// Verify SMTP connection
await transporter.verify();
console.log("✅ SMTP connection verified.");

    const htmlContent = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>${title}</title>
      <style>
        body { font-family: Arial, sans-serif; background-color: #f4f7f5; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 24px rgba(0,0,0,0.06); border: 1px solid #e1e8e3; }
        .header { background: linear-gradient(135deg, #2e7d32, #43a047); padding: 30px 20px; text-align: center; color: #ffffff; }
        .header h1 { margin: 0; font-size: 26px; font-weight: bold; }
        .content { padding: 40px 30px; color: #333333; }
        .content h2 { font-size: 20px; color: #2e7d32; margin-top: 0; }
        .details-table { width: 100%; margin: 24px 0; border-collapse: collapse; }
        .details-table td { padding: 12px 8px; border-bottom: 1px solid #eff3f0; font-size: 14px; }
        .details-table td.label { font-weight: bold; color: #555555; width: 30%; }
        .details-table td.value { color: #222222; }
        .footer { background-color: #f8faf9; padding: 20px; text-align: center; font-size: 12px; color: #777777; border-top: 1px solid #eff3f0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>EchoThread</h1>
          <p style="margin: 5px 0 0 0; opacity: 0.9;">Connecting Donors, NGOs & Volunteers</p>
        </div>
        <div class="content">
          <h2>${title}</h2>
          <p>Hello <strong>${userName}</strong>,</p>
          ${detailsHtml}
          <br/>
          <p><strong>Contact Information:</strong> ${contactInfo}</p>
        </div>
        <div class="footer">
          <p>EchoThread &copy; 2026. All rights reserved.</p>
        </div>
      </div>
    </body>
    </html>
    `;

    const formattedFrom = from.includes('<') ? from : `"EchoThread Platform" <${from}>`;

    await transporter.sendMail({
      from: formattedFrom,
      to: toEmail,
      subject: subject,
      html: htmlContent,
    });
    console.log(`[EMAIL SENT SUCCESS] To: ${toEmail}`);
  } catch (err) {
    console.error(`[EMAIL ERROR] Failed sending to ${toEmail}:`, err);
    throw err;
  }
}

// Reusable Specific Templates
async function sendWelcomeEmail({ email, name, role }) {
  const detailsHtml = `
    <p>Thank you for registering on <strong>EchoThread</strong>. Your account has been setup successfully!</p>
    <table class="details-table">
      <tr><td class="label">Name</td><td class="value">${name}</td></tr>
      <tr><td class="label">Email</td><td class="value">${email}</td></tr>
      <tr><td class="label">Role</td><td class="value">${role}</td></tr>
      <tr><td class="label">Date</td><td class="value">${new Date().toLocaleString()}</td></tr>
    </table>
    <p>We are excited to have you join our platform. Let's make a difference together!</p>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Welcome to EchoThread! 🎉',
    title: 'Account Registration Confirmation',
    userName: name,
    detailsHtml,
    contactInfo: 'Email: support@echothread.org | Web: www.echothread.org'
  });
}

async function sendPasswordResetEmail({ email, name, otp }) {
  const detailsHtml = `
    <p>A request was made to reset your account password. Please enter the following 6-digit OTP code inside the EchoThread application to reset your password:</p>
    <div style="font-size: 24px; font-weight: bold; background-color: #f1f8f3; color: #2e7d32; padding: 12px; border-radius: 8px; text-align: center; letter-spacing: 4px; margin: 20px 0;">
      ${otp}
    </div>
    <p>This code will expire in <strong>5 minutes</strong>. If you did not make this request, you can safely ignore this email.</p>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Password Reset OTP Verification Code 🔑',
    title: 'Password Reset Request',
    userName: name,
    detailsHtml,
    contactInfo: 'Email: support@echothread.org'
  });
}

async function sendOtpEmail({ email, name, otp, purpose }) {
  const activity = purpose === 'register' ? 'Registration' : 'Login';
  const detailsHtml = `
    <p>Please enter the following 6-digit OTP code inside the EchoThread application to complete your ${activity}:</p>
    <div style="font-size: 24px; font-weight: bold; background-color: #f1f8f3; color: #2e7d32; padding: 12px; border-radius: 8px; text-align: center; letter-spacing: 4px; margin: 20px 0;">
      ${otp}
    </div>
    <p>This code will expire in <strong>5 minutes</strong>. If you did not request this, you can safely ignore this email.</p>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: `EchoThread ${activity} Verification Code 🔑`,
    title: `${activity} Verification`,
    userName: name,
    detailsHtml,
    contactInfo: 'Email: support@echothread.org'
  });
}

async function sendDonationCreatedEmail({ email, name, clothes, quantity, location, pickupDate }) {
  const detailsHtml = `
    <p>Your garment donation request has been submitted successfully and is pending NGO assignment.</p>
    <table class="details-table">
      <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
      <tr><td class="label">Quantity</td><td class="value">${quantity}</td></tr>
      <tr><td class="label">Pickup Address</td><td class="value">${location}</td></tr>
      <tr><td class="label">Scheduled Date</td><td class="value">${pickupDate}</td></tr>
      <tr><td class="label">Time</td><td class="value">${new Date().toLocaleString()}</td></tr>
    </table>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Donation Created Successfully 📦',
    title: 'New Donation Request',
    userName: name,
    detailsHtml,
    contactInfo: `Email: ${email}`
  });
}

async function sendDonationAcceptedEmail({ email, name, clothes, quantity, location, volunteerName, volunteerPhone }) {
  const detailsHtml = `
    <p>Good news! Your donation has been accepted by volunteer <strong>${volunteerName}</strong> and is currently being processed for pickup.</p>
    <table class="details-table">
      <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
      <tr><td class="label">Quantity</td><td class="value">${quantity}</td></tr>
      <tr><td class="label">Pickup Address</td><td class="value">${location}</td></tr>
      <tr><td class="label">Volunteer Name</td><td class="value">${volunteerName}</td></tr>
      <tr><td class="label">Volunteer Contact</td><td class="value">${volunteerPhone}</td></tr>
    </table>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Volunteer Assigned to Your Donation 🚗',
    title: 'Donation Pickup in Progress',
    userName: name,
    detailsHtml,
    contactInfo: `Volunteer: ${volunteerName} (${volunteerPhone}) | Donor: ${name}`
  });
}

async function sendDonationDeliveredEmail({ email, name, clothes, quantity }) {
  const detailsHtml = `
    <p>Thank you! Your donation has been successfully delivered and completed by our volunteer network.</p>
    <table class="details-table">
      <tr><td class="label">Garments</td><td class="value">${clothes}</td></tr>
      <tr><td class="label">Quantity</td><td class="value">${quantity}</td></tr>
      <tr><td class="label">Status</td><td class="value" style="color: green; font-weight: bold;">DELIVERED / COMPLETED</td></tr>
      <tr><td class="label">Date & Time</td><td class="value">${new Date().toLocaleString()}</td></tr>
    </table>
    <p>Your contribution helps make the world a warmer and more sustainable place.</p>
  `;

  await sendHTMLEmail({
    toEmail: email,
    subject: 'Donation Successfully Completed! 🎉',
    title: 'Donation Completed',
    userName: name,
    detailsHtml,
    contactInfo: `Donor: ${name}`
  });
}

module.exports = {
  sendHTMLEmail,
  sendWelcomeEmail,
  sendPasswordResetEmail,
  sendOtpEmail,
  sendDonationCreatedEmail,
  sendDonationAcceptedEmail,
  sendDonationDeliveredEmail
};
