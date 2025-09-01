const mongoose = require('mongoose');

const applicationSchema = new mongoose.Schema(
  {
    jobID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Job",
      required: true,
    },
    jobseekerID: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "JobSeeker",
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
    },
    resumeLink: {
      type: String,
    },
    address: {
      type: String,
      required: true,
    },
    contactInfo: {
      type: String,
      required: true,
    },
    status: {
      type: String,
      enum: ["Pending", "Shortlisted", "Accepted", "Rejected"],
      default: "Pending",
    },
    appliedOn: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Application", applicationSchema);
