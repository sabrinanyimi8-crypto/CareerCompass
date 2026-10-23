import 'models.dart';

// These lists are what the assessment screens show as options. The career
// records below use the same wording so the matching actually lines up - if you
// add an option here you need to add it to some careers too or nothing matches.

const List<String> interestOptions = [
  'Programming',
  'Data and statistics',
  'Networks',
  'Cyber security',
  'Design',
  'Business',
  'Research',
  'Hardware',
  'Working with people',
  'Problem solving',
  'Writing',
  'Mathematics',
  'Gaming',
];

const List<String> skillOptions = [
  'Coding',
  'Databases',
  'Communication',
  'Teamwork',
  'Analytical thinking',
  'Attention to detail',
  'Leadership',
  'Creativity',
  'Troubleshooting',
  'Project management',
  'Report writing',
  'Maths',
];

const List<String> workStyleOptions = [
  'Office based',
  'Remote',
  'Hybrid',
  'Fieldwork',
];

const List<String> goalOptions = [
  'High salary',
  'Work overseas',
  'Start my own business',
  'Job security',
  'Help people',
  'Keep learning new technology',
  'Leadership role',
  'Postgraduate study',
];

const List<String> subjectAreaOptions = [
  'Programming',
  'Databases',
  'Networking',
  'Mathematics',
  'Information Systems',
  'Statistics',
  'Security',
  'Design',
  'Business',
];

// Salary ranges are monthly and in rands. Got these from job sites so they are
// rough, they are only there to give the student an idea.
List<Career> careers = [
  Career(
    careerId: 'c01',
    title: 'Software Developer',
    description:
        'Builds and maintains software applications for a company or for clients. Most of the day is '
        'spent writing code, fixing bugs and working through requirements with the rest of the team.',
    field: 'Software Development',
    relatedInterests: ['Programming', 'Problem solving', 'Design'],
    requiredSkills: ['Coding', 'Analytical thinking', 'Teamwork', 'Attention to detail'],
    relevantSubjectAreas: ['Programming', 'Databases'],
    minimumAverage: 55,
    workStyle: 'Hybrid',
    salaryRange: 'R25 000 - R55 000 per month',
    qualificationsNeeded: [
      'BSc Information Technology',
      'Diploma in Software Development',
      'BSc Computer Science',
    ],
    goalTags: ['High salary', 'Work overseas', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c02',
    title: 'Mobile Application Developer',
    description:
        'Develops apps for Android and iOS. Works closely with designers and testers and has to think '
        'about things like screen sizes, offline use and data costs.',
    field: 'Software Development',
    relatedInterests: ['Programming', 'Design', 'Problem solving'],
    requiredSkills: ['Coding', 'Creativity', 'Attention to detail', 'Teamwork'],
    relevantSubjectAreas: ['Programming', 'Design'],
    minimumAverage: 55,
    workStyle: 'Remote',
    salaryRange: 'R22 000 - R50 000 per month',
    qualificationsNeeded: [
      'BSc IT: Mobile Application and Web Services',
      'Diploma in Software Development',
    ],
    goalTags: ['Start my own business', 'Work overseas', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c03',
    title: 'Data Scientist',
    description:
        'Uses statistics and programming to find patterns in large data sets and build models that '
        'help a business make decisions.',
    field: 'Data and Analytics',
    relatedInterests: ['Data and statistics', 'Mathematics', 'Research', 'Programming'],
    requiredSkills: ['Analytical thinking', 'Maths', 'Coding', 'Report writing'],
    relevantSubjectAreas: ['Statistics', 'Mathematics', 'Programming'],
    minimumAverage: 65,
    workStyle: 'Hybrid',
    salaryRange: 'R35 000 - R75 000 per month',
    qualificationsNeeded: [
      'BSc Data Science',
      'BSc Mathematical Statistics',
      'Honours in Data Science',
    ],
    goalTags: ['High salary', 'Postgraduate study', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c04',
    title: 'Data Analyst',
    description:
        'Pulls reports out of company data, builds dashboards and explains what the numbers mean to '
        'people who are not technical.',
    field: 'Data and Analytics',
    relatedInterests: ['Data and statistics', 'Business', 'Problem solving'],
    requiredSkills: ['Analytical thinking', 'Databases', 'Report writing', 'Communication'],
    relevantSubjectAreas: ['Statistics', 'Databases', 'Information Systems'],
    minimumAverage: 55,
    workStyle: 'Office based',
    salaryRange: 'R20 000 - R42 000 per month',
    qualificationsNeeded: [
      'BSc Information Technology',
      'BCom Information Systems',
      'Diploma in Business Analysis',
    ],
    goalTags: ['Job security', 'High salary'],
  ),
  Career(
    careerId: 'c05',
    title: 'Network Engineer',
    description:
        'Designs and looks after the networks a company runs on. Involves routers, switches, '
        'firewalls and a fair amount of troubleshooting when things go down.',
    field: 'Infrastructure',
    relatedInterests: ['Networks', 'Hardware', 'Problem solving'],
    requiredSkills: ['Troubleshooting', 'Attention to detail', 'Analytical thinking'],
    relevantSubjectAreas: ['Networking'],
    minimumAverage: 50,
    workStyle: 'Fieldwork',
    salaryRange: 'R20 000 - R48 000 per month',
    qualificationsNeeded: [
      'Diploma in Network Engineering',
      'BSc Information Technology',
      'CCNA certification',
    ],
    goalTags: ['Job security', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c06',
    title: 'Cyber Security Analyst',
    description:
        'Monitors systems for attacks, investigates incidents and puts controls in place to keep '
        'company and customer data safe.',
    field: 'Security',
    relatedInterests: ['Cyber security', 'Networks', 'Problem solving', 'Research'],
    requiredSkills: ['Analytical thinking', 'Attention to detail', 'Troubleshooting', 'Report writing'],
    relevantSubjectAreas: ['Security', 'Networking'],
    minimumAverage: 60,
    workStyle: 'Office based',
    salaryRange: 'R30 000 - R65 000 per month',
    qualificationsNeeded: [
      'BSc IT: Cyber Security',
      'Diploma in Information Technology',
      'CompTIA Security+',
    ],
    goalTags: ['High salary', 'Job security', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c07',
    title: 'Database Administrator',
    description:
        'Keeps company databases running, backed up and performing properly. Also handles user access '
        'and writes the odd query for other departments.',
    field: 'Data and Analytics',
    relatedInterests: ['Data and statistics', 'Problem solving'],
    requiredSkills: ['Databases', 'Attention to detail', 'Troubleshooting'],
    relevantSubjectAreas: ['Databases'],
    minimumAverage: 55,
    workStyle: 'Office based',
    salaryRange: 'R25 000 - R55 000 per month',
    qualificationsNeeded: [
      'BSc Information Technology',
      'Diploma in Information Technology',
      'Oracle or Microsoft SQL certification',
    ],
    goalTags: ['Job security', 'High salary'],
  ),
  Career(
    careerId: 'c08',
    title: 'UX / UI Designer',
    description:
        'Works out how an app or website should look and flow, draws wireframes and prototypes, and '
        'tests them with real users before anything gets built.',
    field: 'Design',
    relatedInterests: ['Design', 'Working with people', 'Research'],
    requiredSkills: ['Creativity', 'Communication', 'Attention to detail', 'Teamwork'],
    relevantSubjectAreas: ['Design', 'Information Systems'],
    minimumAverage: 50,
    workStyle: 'Remote',
    salaryRange: 'R20 000 - R45 000 per month',
    qualificationsNeeded: [
      'BA Multimedia Design',
      'Diploma in Graphic Design',
      'BSc IT with a design elective',
    ],
    goalTags: ['Start my own business', 'Work overseas'],
  ),
  Career(
    careerId: 'c09',
    title: 'Business Analyst',
    description:
        'Sits between the business and the developers. Gathers requirements, writes them up properly '
        'and makes sure what gets built is what was actually asked for.',
    field: 'Business and IT',
    relatedInterests: ['Business', 'Working with people', 'Writing', 'Problem solving'],
    requiredSkills: ['Communication', 'Report writing', 'Analytical thinking', 'Teamwork'],
    relevantSubjectAreas: ['Information Systems', 'Business'],
    minimumAverage: 55,
    workStyle: 'Hybrid',
    salaryRange: 'R28 000 - R60 000 per month',
    qualificationsNeeded: [
      'BCom Information Systems',
      'BSc Information Technology',
      'Diploma in Business Analysis',
    ],
    goalTags: ['Leadership role', 'High salary'],
  ),
  Career(
    careerId: 'c10',
    title: 'IT Project Manager',
    description:
        'Runs IT projects from start to finish. Plans the work, manages the budget and the team, and '
        'reports progress to management.',
    field: 'Business and IT',
    relatedInterests: ['Business', 'Working with people'],
    requiredSkills: ['Project management', 'Leadership', 'Communication', 'Teamwork'],
    relevantSubjectAreas: ['Information Systems', 'Business'],
    minimumAverage: 55,
    workStyle: 'Office based',
    salaryRange: 'R35 000 - R80 000 per month',
    qualificationsNeeded: [
      'BCom Information Systems',
      'BSc Information Technology',
      'PMP or PRINCE2 certification',
    ],
    goalTags: ['Leadership role', 'High salary'],
  ),
  Career(
    careerId: 'c11',
    title: 'Cloud Engineer',
    description:
        'Sets up and maintains systems running on cloud platforms like AWS or Azure, including '
        'automating deployments and watching costs.',
    field: 'Infrastructure',
    relatedInterests: ['Networks', 'Programming', 'Problem solving'],
    requiredSkills: ['Coding', 'Troubleshooting', 'Analytical thinking'],
    relevantSubjectAreas: ['Networking', 'Programming'],
    minimumAverage: 60,
    workStyle: 'Remote',
    salaryRange: 'R40 000 - R85 000 per month',
    qualificationsNeeded: [
      'BSc Information Technology',
      'AWS or Azure certification',
    ],
    goalTags: ['High salary', 'Work overseas', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c12',
    title: 'Systems Administrator',
    description:
        'Looks after servers, user accounts and the day to day IT that a company needs to keep '
        'working. A lot of support work and maintenance.',
    field: 'Infrastructure',
    relatedInterests: ['Hardware', 'Networks', 'Working with people'],
    requiredSkills: ['Troubleshooting', 'Communication', 'Attention to detail'],
    relevantSubjectAreas: ['Networking', 'Information Systems'],
    minimumAverage: 45,
    workStyle: 'Office based',
    salaryRange: 'R15 000 - R35 000 per month',
    qualificationsNeeded: [
      'Diploma in Information Technology',
      'A+ and N+ certification',
    ],
    goalTags: ['Job security', 'Help people'],
  ),
  Career(
    careerId: 'c13',
    title: 'Software Tester',
    description:
        'Tests software before it goes out, writes up the bugs found and checks that fixes actually '
        'work. Some testers also write automated test scripts.',
    field: 'Software Development',
    relatedInterests: ['Problem solving', 'Programming', 'Writing'],
    requiredSkills: ['Attention to detail', 'Report writing', 'Analytical thinking'],
    relevantSubjectAreas: ['Programming', 'Information Systems'],
    minimumAverage: 45,
    workStyle: 'Hybrid',
    salaryRange: 'R18 000 - R40 000 per month',
    qualificationsNeeded: [
      'Diploma in Information Technology',
      'BSc Information Technology',
      'ISTQB Foundation certificate',
    ],
    goalTags: ['Job security'],
  ),
  Career(
    careerId: 'c14',
    title: 'Game Developer',
    description:
        'Builds games using an engine like Unity or Unreal. Involves a lot of programming plus some '
        'maths for physics and graphics.',
    field: 'Software Development',
    relatedInterests: ['Gaming', 'Programming', 'Design', 'Mathematics'],
    requiredSkills: ['Coding', 'Creativity', 'Maths', 'Teamwork'],
    relevantSubjectAreas: ['Programming', 'Mathematics', 'Design'],
    minimumAverage: 60,
    workStyle: 'Office based',
    salaryRange: 'R20 000 - R50 000 per month',
    qualificationsNeeded: [
      'BSc Computer Science',
      'Diploma in Game Design and Development',
    ],
    goalTags: ['Start my own business', 'Work overseas', 'Keep learning new technology'],
  ),
  Career(
    careerId: 'c15',
    title: 'IT Lecturer',
    description:
        'Teaches IT subjects at a college or university, sets and marks assessments, and usually does '
        'some research alongside the teaching.',
    field: 'Education',
    relatedInterests: ['Working with people', 'Research', 'Writing', 'Programming'],
    requiredSkills: ['Communication', 'Report writing', 'Leadership'],
    relevantSubjectAreas: ['Information Systems', 'Programming'],
    minimumAverage: 65,
    workStyle: 'Office based',
    salaryRange: 'R25 000 - R55 000 per month',
    qualificationsNeeded: [
      'BSc Honours in Information Technology',
      'MSc Information Technology',
      'PGCE for some posts',
    ],
    goalTags: ['Help people', 'Postgraduate study', 'Job security'],
  ),
];

Career findCareer(String id) {
  for (var c in careers) {
    if (c.careerId == id) {
      return c;
    }
  }
  return careers[0];
}
