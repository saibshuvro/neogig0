const express = require('express');
const jwt = require('jsonwebtoken');
const JobSeeker = require('../db/models/JobSeeker');

const router = express.Router();

// Auth middleware (JWT from Authorization header)
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });
  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET); // { id, role, exp }
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid/expired token' });
  }
}

async function requireJobSeeker(req, res, next) {
  if (req.user?.role !== 'JobSeeker') {
    return res.status(403).json({ error: 'JobSeeker access required' });
  }
  // Ensure the account still exists (helps after deletion)
  const exists = await JobSeeker.exists({ _id: req.user.id });
  if (!exists) return res.status(401).json({ error: 'Account not found (deleted/disabled)' });
  next();
}

/**
 * GET /api/jobseeker/me
 * Returns jobseeker profile (excluding email & password)
 */
router.get('/me', auth, requireJobSeeker, async (req, res) => {
  const js = await JobSeeker.findById(req.user.id).select(
    'name description resumeLink address contactInfo createdAt updatedAt'
  );
  if (!js) return res.status(404).json({ error: 'JobSeeker not found' });
  res.json({ jobSeeker: js });
});

/**
 * PUT /api/jobseeker
 * Update allowed fields
 * body: { name?, description?, resumeLink?, address?, contactInfo? }
 */
router.put('/', auth, requireJobSeeker, async (req, res) => {
  const allowed = ['name', 'description', 'resumeLink', 'address', 'contactInfo'];
  const update = {};
  for (const k of allowed) {
    if (k in req.body) update[k] = req.body[k];
  }

  try {
    const js = await JobSeeker.findByIdAndUpdate(req.user.id, update, {
      new: true,
      runValidators: true,
      select: 'name description resumeLink address contactInfo createdAt updatedAt',
    });
    if (!js) return res.status(404).json({ error: 'JobSeeker not found' });
    res.json({ message: 'Updated', jobSeeker: js });
  } catch (err) {
    if (err.name === 'ValidationError') {
      return res.status(400).json({ error: err.message });
    }
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

/**
 * DELETE /api/jobseeker
 * Deletes the jobseeker account
 */
router.delete('/', auth, requireJobSeeker, async (req, res) => {
  const doc = await JobSeeker.findByIdAndDelete(req.user.id);
  if (!doc) return res.status(404).json({ error: 'JobSeeker not found' });
  res.json({ message: 'Deleted' });
});

module.exports = router;
