const mongoose = require('mongoose');

const JobSeekerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
    },
    description: {
      type: String,
      default: '',
      maxlength: 2000,
    },
    resumeLink: {
      type: String,
      default: '',
      maxlength: 500,
    },
    address: {
      type: String,
      required: true,
      // default: '',
      maxlength: 300,
    },
    contactInfo: {
      type: String,
      required: true,
      // default: '',
      maxlength: 200,
    },
    passwordHash: {
      type: String,
      required: true,
      select: false,
    },
    // profilePicture: to be added later
  },
  { timestamps: true, collection: 'jobseeker' }
);

module.exports = mongoose.model('JobSeeker', JobSeekerSchema);
