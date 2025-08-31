const express = require('express');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
const Job = require('../db/models/Job');
const Company = require('../db/models/Company');

const router = express.Router();

// Minimal auth middleware (JWT in Authorization header)
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // { id, role, iat, exp }
    next();
  } catch (e) {
    return res.status(401).json({ error: 'Invalid/expired token' });
  }
}

function requireCompany(req, res, next) {
  if (req.user?.role !== 'Company') {
    return res.status(403).json({ error: 'Company access required' });
  }
  next();
}

/**
 * POST /api/create/job
 * Create a new job listing
 * body: { title, pay, description, schedule, isUrgent? }
 */
router.post('/create', auth, requireCompany, async (req, res) => {
  const { title, pay, description = '', schedule, isUrgent = false } = req.body;

  if (!title || !pay || !schedule) {
    return res.status(400).json({ error: 'All fields are required' });
  }

  try {
    // The company creating the job
    const company = await Company.findById(req.user.id);
    if (!company) return res.status(404).json({ error: 'Company not found' });

    // Create the new job document
    const newJob = new Job({
      companyID: company._id,
      title,
      pay,
      description,
      schedule,
      isUrgent,
    });

    await newJob.save();

    return res.status(201).json({ message: 'Job created successfully', job: newJob });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * PUT /api/job/:id
 * Update job listing details
 * body: { title?, pay?, description?, schedule?, isUrgent? }
 */
router.put('/:id', auth, requireCompany, async (req, res) => {
  const { title, pay, description, schedule, isUrgent } = req.body;
  const update = {};

  if (title) update.title = title;
  if (pay) update.pay = pay;
  if (description) update.description = description;
  if (schedule) update.schedule = schedule;
  if (typeof isUrgent !== 'undefined') update.isUrgent = isUrgent;

  try {
    const job = await Job.findByIdAndUpdate(req.params.id, update, {
      new: true,
      runValidators: true,
    });

    if (!job) return res.status(404).json({ error: 'Job not found' });

    res.json({ message: 'Job updated', job });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * DELETE /api/job/:id
 * Delete a job listing by ID
 */
router.delete('/:id', auth, requireCompany, async (req, res) => {
  try {
    const job = await Job.findByIdAndDelete(req.params.id);
    if (!job) return res.status(404).json({ error: 'Job not found' });

    res.json({ message: 'Job deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


// GET /api/job/mine
// List jobs created by the authenticated company
router.get('/mine', auth, requireCompany, async (req, res) => {
  try {
    const companyId = req.user.id;

    // Validate the companyId to make sure it's an ObjectId
    if (!mongoose.isValidObjectId(companyId)) {
      return res.status(400).json({ error: 'Invalid company id in token' });
    }

    // Fetch all jobs created by this company
    const jobs = await Job.find({ companyID: companyId }).sort({ postedOn: -1 });

    res.json({ jobs });
  } catch (err) {
    console.error('[GET /mine] Error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * GET /api/job/:id
 */
router.get('/:id', async (req, res) => {
  try {
    if (!mongoose.isValidObjectId(req.params.id)) {          // <— validate
      return res.status(400).json({ error: 'Invalid job id' });
    }
    const job = await Job.findById(req.params.id).populate('companyID', 'name');
    if (!job) return res.status(404).json({ error: 'Job not found' });
    res.json({ job });
  } catch (err) {
    console.error('[GET /:id] Error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});


// GET /api/job
router.get('/', async (req, res) => {
  try {
    const jobs = await Job.find()
      .populate('companyID', 'name') // <-- add this
      .sort({ postedOn: -1 });
    res.json({ jobs });
  } catch (err) {
    console.error('[GET /] Error:', err);
    res.status(500).json({ error: 'Server error' });
  }
});


module.exports = router;
