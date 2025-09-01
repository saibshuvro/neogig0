require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

// Import routes
const signupRoutes = require('./routes/signup');
const loginRoutes = require('./routes/login');
const companyRoutes = require('./routes/company');
const jobSeekerRoutes = require('./routes/jobseeker');
const jobRoutes = require('./routes/job');
const savedJobRoutes = require('./routes/savedJob');
const applicationRoutes = require('./routes/application');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Use routes
app.use('/api/signup', signupRoutes);
app.use('/api/login', loginRoutes);
app.use('/api/company', companyRoutes);
app.use('/api/jobseeker', jobSeekerRoutes);
app.use('/api/job', jobRoutes);
app.use('/api/savedjob', savedJobRoutes);
app.use('/api/application', applicationRoutes);

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB connected successfully!'))
  .catch((err) => {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1);
  });

// Root Route
app.get('/', (req, res) => {
  res.send('Welcome to the API!');
});

// Error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal Server Error' });
});

const PORT = process.env.PORT || 1060;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
