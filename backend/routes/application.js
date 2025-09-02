const express = require('express');
// const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');
// const Job = require('../db/models/Job');
// const Company = require('../db/models/Company');
const Application = require('../db/models/Application');

const router = express.Router();

// Minimal auth middleware (JWT in Authorization header)
function auth(req, res, next) {
  const h = req.headers.authorization || '';
  const token = h.startsWith('Bearer ') ? h.slice(7) : null;
  if (!token) return res.status(401).json({ error: 'Missing token' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    // console.log("Decoded JWT:", decoded);  // Log the decoded token
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

function requireJobSeeker(req, res, next) {
  if (req.user?.role !== 'JobSeeker') {
    return res.status(403).json({ error: 'JobSeeker access required' });
  }
  next();
}


router.post("/", auth, requireJobSeeker, async (req, res) => {
  try {
    const { jobID, name, description = '', resumeLink = '', address, contactInfo } = req.body;

    if (!jobID || !name || !address || !contactInfo) {
      return res.status(400).json({ message: "Missing required fields" });
    }

    // Optional: validate ObjectId
    // if (!mongoose.Types.ObjectId.isValid(jobID)) {
    //   return res.status(400).json({ message: "Invalid jobID" });
    // }

    // Fast pre-check to return a friendly message
    const existing = await Application
      .findOne({ jobID, jobseekerID: req.user.id })
      .select('_id')
      .lean();

    if (existing) {
      return res.status(409).json({ message: "You have already applied to this job." });
    }

    const application = new Application({
      jobID,
      jobseekerID: req.user.id,
      name,
      description,
      resumeLink,
      address,
      contactInfo,
      status: "Pending",
    });

    const saved = await application.save();
    return res.status(201).json(saved);

  } catch (error) {
    // If two requests race, unique index guarantees prevention
    if (error && error.code === 11000) {
      return res.status(409).json({ message: "You have already applied to this job." });
    }
    console.error("Application POST error:", error);
    return res.status(500).json({ message: "Server error" });
  }
});


// GET /api/application/my
// Fetch all applications for the authenticated JobSeeker
router.get("/my", auth, requireJobSeeker, async (req, res) => {
  try {
    // Get all applications by the authenticated JobSeeker
    const apps = await Application.find({ jobseekerID: req.user.id })
      .populate("jobID", "title companyID") // Populate job title and company info
      .sort({ createdAt: -1 }); // Sort by application date (latest first)

    res.json(apps);  // Return the list of applications
  } catch (error) {
    console.error("Get applications error:", error);
    res.status(500).json({ message: "Server error" });
  }
});


// DELETE /api/application/:id
// Withdraw an application (delete the application)
router.delete("/:id", auth, requireJobSeeker, async (req, res) => {
  try {
    const applicationId = req.params.id;

    // Find and delete the application
    const application = await Application.findByIdAndDelete(applicationId);

    if (application.jobseekerID.toString() !== req.user.id.toString()) {
        return res.status(403).json({ message: "Unauthorized action" });
        }


    if (!application) {
      return res.status(404).json({ message: "Application not found" });
    }

    res.json({ message: "Application withdrawn successfully" });
  } catch (error) {
    console.error("Withdraw application error:", error);
    res.status(500).json({ message: "Server error" });
  }
});


// GET /api/application/:id
// Fetch the details of a single application
router.get("/:id", async (req, res) => {
  try {
    const application = await Application.findById(req.params.id)
      .populate("jobID", "title")  // Populate job title
      .populate("jobseekerID", "name")  // Populate jobseeker name (if needed)
      .exec();

    if (!application) {
      return res.status(404).json({ message: "Application not found" });
    }

    res.json({ application });  // Send the application details back
  } catch (error) {
    console.error("Get application error:", error);
    res.status(500).json({ message: "Server error" });
  }
});


// GET /api/application/job/:jobId
// Fetch all applications for a specific job
router.get("/job/:jobId", auth, requireCompany, async (req, res) => {
  try {
    const jobId = req.params.jobId;

    // Find all applications for the specified job
    const applications = await Application.find({ jobID: jobId })
      .populate("jobseekerID", "name")  // Populate applicant's name
      .sort({ appliedOn: -1 });  // Sort applications by applied date (latest first)

    if (!applications.length) {
      return res.status(404).json({ message: "No applications found for this job" });
    }

    res.json({ applications });  // Send all applications for the job
  } catch (error) {
    console.error("Get applications for job error:", error);
    res.status(500).json({ message: "Server error" });
  }
});


// PUT /api/application/:id
// Update the status of an application
router.put("/:id", auth, requireCompany, async (req, res) => {
  try {
    const { status } = req.body;
    const applicationId = req.params.id;

    // Validate the status
    if (!['Pending', 'Shortlisted', 'Accepted', 'Rejected'].includes(status)) {
      return res.status(400).json({ message: "Invalid status" });
    }

    // Find and update the application status
    const application = await Application.findByIdAndUpdate(
      applicationId,
      { status },
      { new: true, runValidators: true }
    );

    if (!application) {
      return res.status(404).json({ message: "Application not found" });
    }

    res.json({ message: "Application status updated", application });
  } catch (error) {
    console.error("Update application status error:", error);
    res.status(500).json({ message: "Server error" });
  }
});


module.exports = router;
