const mongoose = require('mongoose');

const JobSchema = new mongoose.Schema({
  companyID: {
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'Company',
    required: true
  },
  title: {
    type: String,
    required: true
  },
  pay: {
    type: String,
    required: true
  },
  description: {
    type: String,
    // required: true
    default: '',
    maxlength: 3000,
  },
  schedule: [{
    day: {
      type: String,
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
      required: true
    },
    time_start: {
      type: String, // Store as "HH:mm" format, or use Date object if precise time comparison is needed
      required: true
    },
    time_end: {
      type: String, // Store as "HH:mm" format, or use Date object if precise time comparison is needed
      required: true
    }
  }],
  isUrgent: {
    type: Boolean,
    default: false
  },
  postedOn: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Job', JobSchema, 'job');
