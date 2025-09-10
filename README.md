# 🚛 RV Truck Fleet Management System

A comprehensive Flutter-based fleet management application with Supabase backend, designed for managing RV truck operations, trips, drivers, and fleet resources.

## 🌟 Features

### 🔐 Role-Based Access Control
- **Admin**: Complete system management, user approvals, fleet oversight
- **Trip Manager**: Trip creation, assignment, and monitoring
- **Driver**: Trip execution, expense tracking, advance management
- **Accountant**: Financial oversight and reporting
- **Pump Partner**: Fuel management and tracking

### 📱 Core Functionality
- **Trip Management**: Create, assign, track, and settle trips
- **Fleet Management**: Vehicle status tracking and maintenance
- **Driver Management**: Driver profiles, licensing, and assignment
- **Expense Tracking**: Real-time expense and advance management
- **Financial Reporting**: Commission tracking and financial summaries
- **Real-time Updates**: Live data synchronization across all devices

### 🎯 Key Capabilities
- ✅ **Trip Lifecycle Management**: Assigned → In Progress → Completed → Settled
- ✅ **Fleet Status Tracking**: Active, Inactive, Maintenance vehicles
- ✅ **Driver Status Management**: Active, Inactive, Suspended drivers
- ✅ **Flexible Broker System**: Optional broker selection with customizable commission rates
- ✅ **Real-time Dashboard**: Live statistics and status updates
- ✅ **Comprehensive Reporting**: Trip, financial, and operational reports

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile and web development
- **Dart**: Programming language
- **Material Design**: Modern UI/UX components

### Backend
- **Supabase**: Backend-as-a-Service
- **PostgreSQL**: Relational database
- **Row Level Security (RLS)**: Database security
- **REST API**: Data communication

### Development Tools
- **Flutter SDK**: Latest stable version
- **VS Code**: Recommended IDE
- **Git**: Version control

## 📋 Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Supabase account
- Git
- Android Studio / VS Code

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/neesac-ai/transport_app.git
cd transport_app
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
1. Create a new Supabase project
2. Run the SQL scripts in the following order:
   - `business_logic_schema.sql`
   - `email_only_auth.sql`
   - `fixed_rls_policies.sql`
   - `approval_fix.sql`
   - `add_missing_trip_columns.sql`

### 4. Environment Configuration
Create a `.env` file in the root directory:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 5. Run the Application
```bash
# For web development
flutter run -d chrome --web-port=8080

# For mobile development
flutter run
```

## 📁 Project Structure

```
lib/
├── constants/          # App constants and configurations
├── models/            # Data models (Trip, Driver, Vehicle, etc.)
├── screens/           # UI screens for different roles
├── services/          # API services and business logic
└── main.dart         # Application entry point

sql/
├── business_logic_schema.sql    # Main database schema
├── email_only_auth.sql          # Authentication setup
├── fixed_rls_policies.sql       # Security policies
├── approval_fix.sql             # User approval system
└── add_missing_trip_columns.sql # Additional trip columns
```

## 🔧 Database Schema

### Core Tables
- **user_profiles**: User information and role management
- **trips**: Trip details, status, and financial information
- **vehicles**: Fleet vehicle information and status
- **drivers**: Driver profiles and licensing
- **brokers**: Broker information and commission rates
- **expenses**: Trip-related expenses
- **advances**: Driver advance payments

### Key Relationships
- Users → Trips (assigned_by)
- Vehicles → Trips (vehicle_id)
- Drivers → Trips (driver_id)
- Brokers → Trips (broker_id)
- Trips → Expenses (trip_id)
- Trips → Advances (trip_id)

## 🎮 Usage Guide

### Admin Dashboard
- **User Approvals**: Approve/reject user registrations
- **Fleet Overview**: Monitor all vehicles and drivers
- **Reports**: Generate comprehensive system reports
- **Settings**: Configure system parameters

### Trip Manager Dashboard
- **Trip Creation**: Create new trips with flexible broker options
- **Trip Management**: Monitor and update trip statuses
- **Fleet Management**: View all vehicles and their statuses
- **Driver Management**: Monitor driver statuses and assignments

### Driver Dashboard
- **Trip Execution**: Start, complete, and update trip status
- **Expense Tracking**: Record trip-related expenses
- **Advance Management**: Request and track advance payments
- **Profile Management**: Update personal and license information

## 🔒 Security Features

- **Row Level Security (RLS)**: Database-level access control
- **Role-based Permissions**: Granular access control per user role
- **Authentication**: Secure email/password authentication
- **Data Validation**: Comprehensive input validation
- **Audit Trail**: Complete activity logging

## 📊 Key Metrics

- **Trip Status Tracking**: Real-time trip lifecycle monitoring
- **Fleet Utilization**: Vehicle and driver efficiency metrics
- **Financial Tracking**: Commission and expense management
- **Performance Analytics**: Operational efficiency insights

## 🚀 Deployment

### Web Deployment
```bash
flutter build web
# Deploy the build/web directory to your hosting service
```

### Mobile Deployment
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Contact the development team
- Check the documentation in the `/docs` folder

## 🗺️ Roadmap

### Phase 1 ✅ (Completed)
- [x] User authentication and role management
- [x] Basic trip management system
- [x] Fleet and driver management
- [x] Expense and advance tracking

### Phase 2 🔄 (In Progress)
- [ ] Advanced reporting and analytics
- [ ] Mobile app optimization
- [ ] Real-time notifications
- [ ] API documentation

### Phase 3 📋 (Planned)
- [ ] GPS tracking integration
- [ ] Fuel management system
- [ ] Maintenance scheduling
- [ ] Advanced financial reporting

## 🏆 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the robust backend infrastructure
- Material Design for the beautiful UI components
- Open source community for continuous inspiration

---

**Built with ❤️ by the Neesac AI Team**