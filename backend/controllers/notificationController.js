const { sendHTMLEmail } = require('../services/emailService');
const { sendTwilioSMS } = require('../services/smsService');

/**
 * Sends a general email or SMS notification.
 */
exports.sendNotification = async (req, res, next) => {
  try {
    const body = req.body.data || req.body;
    const { recipient, name, type, title, content } = body;

    if (!recipient || !type || !content) {
      return res.status(400).json({ error: 'recipient, type (email/sms), and content are required fields.' });
    }

    const recipientName = name || 'User';

    if (type === 'email') {
      await sendHTMLEmail({
        toEmail: recipient,
        subject: title || 'EchoThread Notification',
        title: title || 'EchoThread Notification',
        userName: recipientName,
        detailsHtml: `<p>${content.replace(/\n/g, '<br/>')}</p>`,
        contactInfo: 'Email: support@echothread.org'
      });
    } else if (type === 'sms') {
      await sendTwilioSMS(recipient, content);
    } else {
      return res.status(400).json({ error: 'Invalid notification type. Supported values: email, sms.' });
    }

    res.status(200).json({
      success: true,
      message: 'Notification sent successfully.'
    });
  } catch (err) {
    next(err);
  }
};
