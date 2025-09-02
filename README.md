
# NeoGig

**NeoGig** is a job-matching platform built using Flutter for the frontend and Node.js for the backend. It connects job seekers and employers, providing tools to apply for jobs, post listings, manage profiles, and track applications. 

This repository contains both the mobile application (frontend) built in **Flutter** and the backend API built in **Node.js**.

## Features

### Job Seeker:
- **Job Search**: Search for available job listings based on different criteria.
- **Job Applications**: Apply to jobs, track application status, and withdraw applications.
- **Saved Jobs**: Save job listings for future reference.
- **Profile Management**: Manage your job seeker profile, including personal information and resume.
- **Job Alerts**: Set up alerts for new job postings matching your preferences.
  
### Company:
- **Post Jobs**: Create job listings with descriptions, pay, and work hours.
- **Manage Applications**: View and manage applications, update application statuses, and communicate with candidates.
- **Company Profile**: Create and manage your company profile with details like location, contact info, and description.
  
### Common:
- **Role-based Access**: Different views and permissions for job seekers and employers.
- **Authentication**: JWT-based login system with secure sessions.

---

## Project Structure

### Backend:
The backend is built using **Node.js** and **Express** to handle job postings, user management, applications, and authentication. 

- **Directory**: `neogig0/backend`
- **Run the Backend**:  
  Navigate to the backend directory and run the server:
  ```bash
  cd neogig0/backend
  node server.js
  ```

### Frontend:
The frontend is a **Flutter** mobile application where users can interact with the system. It communicates with the backend API to fetch job listings, manage profiles, and submit applications.

- **Directory**: `neogig0/lib`
- **Run the Frontend**:  
  To run the Flutter app, use the following command:
  ```bash
  cd neogig0
  flutter run
  ```

---

## Installation

### Backend:
1. Install **Node.js** and **npm** (if not already installed).
2. Navigate to the `neogig0/backend` directory.
3. Install the required dependencies:
   ```bash
   npm install
   ```
4. Set up environment variables:
   - Make sure you have a `.env` file containing the necessary environment variables like `MONGO_URI`, `JWT_SECRET`, etc.
5. Start the server:
   ```bash
   node server.js
   ```

### Frontend:
1. Install **Flutter** (if not already installed).
2. Navigate to the `neogig0` directory.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## APIs

The backend provides several endpoints to interact with the mobile frontend. Here are some of the key endpoints:

### Authentication:
- **POST /api/auth/login**: Login and obtain a JWT token.
- **POST /api/auth/register**: Register a new user (Job Seeker or Company).

### Job Management:
- **GET /api/job**: Get all jobs.
- **POST /api/job/create**: Create a new job listing.
- **GET /api/job/:id**: Get details of a specific job listing.
- **PUT /api/job/:id**: Update a job listing.
- **DELETE /api/job/:id**: Delete a job listing.

### Application Management:
- **GET /api/application/:id**: Get a specific application.
- **POST /api/application**: Apply for a job.
- **DELETE /api/application/:id**: Withdraw an application.

### Company Profile:
- **GET /api/company/:id**: Get details of a company profile.
- **PUT /api/company/:id**: Update company profile.

### Job Seeker Profile:
- **GET /api/jobseeker/:id**: Get a jobseeker’s profile.
- **PUT /api/jobseeker/:id**: Update jobseeker’s profile.

---

## Technology Stack

### Backend:
- **Node.js**: JavaScript runtime for the backend server.
- **Express.js**: Web framework for Node.js.
- **MongoDB**: NoSQL database for storing user, job, and application data.
- **JWT**: JSON Web Tokens for secure authentication.

### Frontend:
- **Flutter**: Open-source framework for building natively compiled applications for mobile (iOS & Android).
- **Dart**: Programming language used to build the Flutter app.

---

## Installation

### Backend:
1. Install **Node.js** and **npm** (if not already installed).
2. Navigate to the `neogig0/backend` directory.
3. Install the required dependencies:
   ```bash
   npm install
   ```
4. Set up environment variables:
   - Make sure you have a `.env` file containing the necessary environment variables like `MONGO_URI`, `JWT_SECRET`, etc.
5. Start the server:
   ```bash
   node server.js
   ```

### Frontend:
1. Install **Flutter** (if not already installed).
2. Navigate to the `neogig0` directory.
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

---

## Contributing

Contributions are welcome! Feel free to fork the repo, submit pull requests, or report issues.

---

## License

This project is open-source and available under the [MIT License](LICENSE).
