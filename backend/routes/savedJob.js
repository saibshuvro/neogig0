const express = require('express');
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');
const SavedJob = require('../db/models/SavedJob');
// const Job = require('../db/models/Job');

const router = express.Router();

// JWT auth middleware
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded; // {id, role}
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid/expired token' });
  }
}

// Save a job
router.post('/:jobId', auth, async (req, res) => {
  try {
    if (req.user.role !== 'JobSeeker') {
      return res.status(403).json({ error: 'Jobseeker access required' });
    }

    const { jobId } = req.params;
    if (!mongoose.isValidObjectId(jobId)) {
      return res.status(400).json({ error: 'Invalid job id' });
    }

    const existing = await SavedJob.findOne({ jobseekerID: req.user.id, jobID: jobId });
    if (existing) {
      return res.status(200).json({ message: 'Already saved' });
    }

    const saved = new SavedJob({ jobseekerID: req.user.id, jobID: jobId });
    await saved.save();

    res.status(201).json({ message: 'Job saved successfully', saved });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// routes/savedJob.js
router.get('/', auth, async (req, res) => {
  try {
    if (req.user.role !== 'JobSeeker') {
      return res.status(403).json({ error: 'Jobseeker access required' });
    }

    const saved = await SavedJob.find({ jobseekerID: req.user.id })
      .populate({
        path: 'jobID',
        populate: { path: 'companyID', select: 'name' }
      });
    
    // console.log(JSON.stringify(saved, null, 2));
    res.json({ saved });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// Unsave a job
router.delete('/:jobId', auth, async (req, res) => {
  try {
    if (req.user.role !== 'JobSeeker') {
      return res.status(403).json({ error: 'Jobseeker access required' });
    }

    const { jobId } = req.params;
    if (!mongoose.isValidObjectId(jobId)) {
      return res.status(400).json({ error: 'Invalid job id' });
    }

    const deleted = await SavedJob.findOneAndDelete({
      jobseekerID: req.user.id,
      jobID: jobId,
    });

    if (!deleted) {
      return res.status(404).json({ error: 'Job not found in saved list' });
    }

    res.json({ message: 'Job unsaved successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});


module.exports = router;
