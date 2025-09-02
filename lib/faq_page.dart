import 'package:flutter/material.dart';
// import 'package:neogig0/widgets/custom_drawer.dart';

class FaqPage extends StatelessWidget {
  final String userRole;

  const FaqPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      // drawer: CustomDrawer(userRole: userRole),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Frequently Asked Questions (FAQ)',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _faqItem(
              'How do I create an account?',
              'To create an account, click on the sign-up button on the homepage and fill in your details. You can sign up as a Job Seeker or Company.',
            ),
            _faqItem(
              'How can I apply for jobs?',
              'Once you have an account, you can browse through available jobs, and if you find one that matches your skills, click the "Apply" button to submit your application.',
            ),
            _faqItem(
              'How can I edit my job application?',
              'To edit your application, go to your profile page and find the job listing you applied to. You can edit your application there if the company hasn’t processed it yet.',
            ),
            _faqItem(
              'How do I withdraw an application?',
              'You can withdraw an application by navigating to the "Application Details" page, and clicking the "Withdraw" button. Confirm the action when prompted.',
            ),
            _faqItem(
              'How can I create a job listing?',
              'If you are a Company, you can create a job listing by going to the "Create Job" section in your profile. Fill in the necessary details and publish your job opening.',
            ),
            // _faqItem(
            //   'What if I forget my password?',
            //   'If you forget your password, you can reset it by clicking the "Forgot Password" link on the login page and following the instructions.',
            // ),
            const SizedBox(height: 24),
            const Text(
              'Still have questions? Contact our support team at support@neogig.com',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(answer),
      ),
    );
  }
}
