const mongoose = require('mongoose');

const SavedJobSchema = new mongoose.Schema({
  jobseekerID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'JobSeeker',
    required: true
  },
  jobID: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Job',
    required: true
  },
  savedOn: {
    type: Date,
    default: Date.now
  }
});

// Ensure one job can’t be saved twice by the same jobseeker
SavedJobSchema.index({ jobseekerID: 1, jobID: 1 }, { unique: true });

module.exports = mongoose.model('SavedJob', SavedJobSchema, 'saved_jobs');
