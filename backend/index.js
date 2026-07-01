require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const otpRoutes = require('./routes/otpRoutes');
const donationRoutes = require('./routes/donationRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const errorHandler = require('./middleware/errorHandler');

const app = express();

// 1. Middleware
app.use(cors());
app.use(express.json());

// 2. Roots / Status check
app.get('/', (req, res) => {
  res.json({
    status: 'EchoThread Backend Running'
  });
});

// 3. API Routes
app.use('/api', authRoutes);
app.use('/api', otpRoutes);
app.use('/api', donationRoutes);
app.use('/api', notificationRoutes);

// 4. Centralized Error Handler Middleware
app.use(errorHandler);

// 5. Initialize Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`[SERVER RUNNING] Express backend listening on port ${PORT}`);
});
