const express = require('express');
const bcrypt = require('bcryptjs');
const Company = require('../db/models/Company');
const JobSeeker = require('../db/models/JobSeeker');

const router = express.Router();

/**
 * POST /api/signup/company
 * body: { name, description?, location?, contactInfo?, email, password }
 */
router.post('/company', async (req, res) => {
  try {
    const { name, description = '', location, contactInfo, email, password } = req.body;

    if (!name || !location || !contactInfo || !email || !password) {
      return res.status(400).json({ error: 'name, location, contactInfo, email, and password are required' });
    }

    const exists = await Company.findOne({ email });
    if (exists) return res.status(409).json({ error: 'Email already registered' });

    const passwordHash = await bcrypt.hash(password, 12);

    const company = await Company.create({
      name,
      description,
      location,
      contactInfo,
      email,
      passwordHash,
    });

    // return minimal safe fields
    return res.status(201).json({
      message: 'Company created',
      company: { id: company._id, name: company.name },
    });
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ error: err.message });
    }
    console.error(err);
    return res.status(500).json({ error: 'Server error' });
  }
});

/**
 * POST /api/signup/jobseeker
 * body: { name, email, password, description?, resumeLink?, address?, contactInfo? }
 */
router.post('/jobseeker', async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      description = '',
      resumeLink = '',
      address,
      contactInfo,
    } = req.body;

    if (!name || !email || !password || !address || !contactInfo) {
      return res.status(400).json({ error: 'name, email, password, address and contactInfo are required' });
    }

    const exists = await JobSeeker.findOne({ email });
    if (exists) return res.status(409).json({ error: 'Email already registered' });

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await JobSeeker.create({
      name,
      email,
      passwordHash,
      description,
      resumeLink,
      address,
      contactInfo,
    });

    return res.status(201).json({
      message: 'JobSeeker created',
      jobSeeker: { id: user._id, name: user.name },
    });
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ error: err.message });
    }
    console.error(err);
    return res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
