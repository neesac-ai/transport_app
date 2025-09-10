RV – Truck Fleet Management App

1. Project Overview

This application is designed to digitize and streamline the management of a commercial truck fleet.
It will support trip earnings, driver payments (silak), diesel and expense management, and overall fleet profitability.
The app reduces manual work, provides real-time operational data, and ensures accountability.

2. Technology Stack

Framework: Flutter (mobile-first, cross-platform)

Backend & Database: Supabase

Authentication: Supabase Auth (Phone Number + OTP)

Storage: Supabase Storage (for odometer photos, receipts, etc.)

Access Control: Role-based

3. User Roles & Permissions

Admin

Full access, manage users, approve expenses, override data.

Traffic Manager

Assign loads, input trip data, approve diesel, manage driver assignments.

Driver

View trips, upload odometer photos, view silak, report issues.

Accountant

Enter expenses, track advances, reconcile diesel usage and settlements.

Pump Partner

Upload diesel refueling data + vehicle photo (via credentials).

4. Authentication Flow

User enters phone number → receives OTP → verifies identity.

On first login, user must complete profile:

Name

Email

Address

Role (Admin / Traffic Manager / Driver / Accountant / Pump Partner)

Session stored securely (Supabase auth).

Splash screen (logo.jpg) → redirect based on login state.

5. Core Modules & Features
A. 🚚 Vehicle & Driver Management

Add, edit, view trucks (registration, RC, permit, insurance).

Driver profiles: name, contact, license, assigned vehicle.

Broker profiles: name, company, contact.

B. 📦 Trip Management

Create trip: truck, driver, broker, route, tonnage, rate, commission.

Auto-generate Loading Receipt (LR).

Track odometer start/end.

Track diesel issued, advance given, silak calculations.

Mark trip as settled or carry-forward.

Carry-forward diesel/advances if driver changes.

C. ⛽ Diesel Management

Modes:

Credit pump partner (via login).

Random pump (entered by Traffic Manager/Accountant).

Diesel cards per vehicle (recharge & limits).

Diesel usage logged per trip, deducted from driver earnings.

D. 💸 Silak & Driver Salary

Silak = allowance for driver (fuel, food, stay).

Formula-based: per km driven OR per liter of diesel.

Record advances & auto-calc balance at trip end.

Show real-time driver earnings.

E. 📷 Odometer Tracking

Mandatory odometer photo upload (start & end).

Distance auto-calculated.

Admin can override manually.

F. 🧾 Expense Management

Categorize expenses: Trip-specific or General.

General expenses split across vehicles.

Upload receipts, assign expense to trip/truck/general.

G. 📈 Earnings & Profitability Dashboard

Reports:

Trips completed

Earnings summary

Expense breakdown

Profit per trip

Diesel usage

Driver balance & settlement history.

H. 📲 Mobile Role-based Access

Owner/Admin → Dashboard of trucks, earnings.

Driver → Trip summary, silak, diesel, advances, photo uploads.

Traffic Manager → Assign trips, enter diesel, monitor progress.

Accountant → Expenses, reconciliations.

6. Advanced Logic & Automations

Diesel Required = Distance ÷ Mileage.

Silak = Distance × per km rate.

Trip Completion: Odometer photo upload → auto-calc diesel & silak.

Driver Switch: Carry forward diesel/advances.

Access Control: Overrides restricted to Admin.

7. Assumptions & Notes

Diesel card system = manual now, but future-ready for digital.

Manual entries (expenses/advances) must still reflect in reports.

Offline-first mobile app (sync with Supabase when online).

Multi-role system with controlled permissions.