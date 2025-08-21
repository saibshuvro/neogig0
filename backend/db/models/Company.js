const mongoose = require('mongoose');

const CompanySchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    description: {
      type: String,
      default: '',
      maxlength: 2000,
    },
    location: {
      type: String,
      required: true,
      // default: '',
      maxlength: 200,
    },
    contactInfo: {
      type: String, // could be phone/email/url; keep free-form for now
      required: true,
      // default: '',
      maxlength: 200,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Invalid email format'],
    },
    passwordHash: {
      type: String,
      required: true,
      select: false, // don’t return by default
    },
    // profilePicture: to be added later
  },
  { timestamps: true, collection: 'company' } // explicit collection name
);

module.exports = mongoose.model('Company', CompanySchema);
