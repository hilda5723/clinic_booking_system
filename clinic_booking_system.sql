-- Clinic Booking System Database
-- Author: Hilda Ruto
-- Date: 5/8/2025
-- Description: This SQL script creates the tables for a clinic booking system.
-- It includes tables for patients, doctors, specializations, services, and appointments,
-- with appropriate constraints and relationships.

-- For idempotency: Drop tables if they exist, in reverse order of creation due to FK constraints.
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Patients;
DROP TABLE IF EXISTS Services;
DROP TABLE IF EXISTS Specializations;

-- -----------------------------------------------------
-- Table `Specializations`
-- Stores different medical specializations.
-- -----------------------------------------------------
CREATE TABLE Specializations (
    specialization_id INT AUTO_INCREMENT PRIMARY KEY,
    specialization_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Table `Services`
-- Stores medical services offered by the clinic.
-- -----------------------------------------------------
CREATE TABLE Services (
    service_id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(150) NOT NULL UNIQUE,
    description TEXT,
    base_cost DECIMAL(10, 2) NOT NULL CHECK (base_cost >= 0), -- Cost of the service
    duration_minutes INT DEFAULT 30 CHECK (duration_minutes > 0), -- Typical duration
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- -----------------------------------------------------
-- Table `Patients`
-- Stores patient information.
-- -----------------------------------------------------
CREATE TABLE Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other', 'Prefer not to say') DEFAULT 'Prefer not to say',
    phone_number VARCHAR(20) UNIQUE, -- Can be NULL if patient prefers email
    email VARCHAR(100) UNIQUE,      -- Can be NULL if patient prefers phone
    address TEXT,
    medical_history_summary TEXT, -- Brief summary, detailed records might be in another system/table
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_contact_info CHECK (phone_number IS NOT NULL OR email IS NOT NULL) -- Ensure at least one contact method
);

-- -----------------------------------------------------
-- Table `Doctors`
-- Stores doctor information and their specialization.
-- -----------------------------------------------------
CREATE TABLE Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    phone_number VARCHAR(20) UNIQUE,
    specialization_id INT, -- A doctor belongs to one specialization
    license_number VARCHAR(50) UNIQUE,
    years_of_experience INT DEFAULT 0 CHECK (years_of_experience >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_doctor_specialization
        FOREIGN KEY (specialization_id)
        REFERENCES Specializations(specialization_id)
        ON DELETE SET NULL -- If a specialization is deleted, the doctor's specialization becomes NULL (or use RESTRICT)
        ON UPDATE CASCADE
);

-- -----------------------------------------------------
-- Table `Appointments`
-- Stores appointment details, linking patients, doctors, and services.
-- This is a central table showing many-to-many effective relationships
-- (via one-to-many from Patients and Doctors to Appointments).
-- -----------------------------------------------------
CREATE TABLE Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    service_id INT, -- An appointment might be for a specific service
    appointment_datetime DATETIME NOT NULL,
    duration_minutes INT DEFAULT 30 CHECK (duration_minutes > 0), -- Actual duration for this appointment
    status ENUM('Scheduled', 'Completed', 'Cancelled_By_Patient', 'Cancelled_By_Clinic', 'No_Show') NOT NULL DEFAULT 'Scheduled',
    reason_for_visit TEXT,
    notes TEXT, -- Notes by doctor or admin
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_appointment_patient
        FOREIGN KEY (patient_id)
        REFERENCES Patients(patient_id)
        ON DELETE CASCADE, -- If a patient is deleted, their appointments are also deleted (consider business rules)
    CONSTRAINT fk_appointment_doctor
        FOREIGN KEY (doctor_id)
        REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT, -- Prevent deleting a doctor if they have appointments (or SET NULL)
    CONSTRAINT fk_appointment_service
        FOREIGN KEY (service_id)
        REFERENCES Services(service_id)
        ON DELETE SET NULL, -- If a service is removed, appointment doesn't lose its service link, just becomes generic
    CONSTRAINT uk_doctor_time UNIQUE (doctor_id, appointment_datetime) -- A doctor cannot have two appointments at the exact same time
    -- CONSTRAINT uk_patient_time UNIQUE (patient_id, appointment_datetime) -- A patient cannot have two appointments at the exact same time (optional, less critical)
);

-- --- Example: Adding some data (Optional, for testing) ---
/*
INSERT INTO Specializations (specialization_name, description) VALUES
('Cardiology', 'Deals with disorders of the heart.'),
('Dermatology', 'Deals with the skin, hair, and nails.'),
('General Practice', 'Primary care for all ages.');

INSERT INTO Services (service_name, description, base_cost, duration_minutes) VALUES
('General Consultation', 'Standard check-up with a GP.', 50.00, 30),
('ECG Test', 'Electrocardiogram test.', 120.00, 45),
('Skin Rash Treatment', 'Consultation and treatment for skin rashes.', 75.00, 30);

INSERT INTO Patients (first_name, last_name, date_of_birth, phone_number, email) VALUES
('John', 'Doe', '1985-06-15', '555-0101', 'john.doe@email.com'),
('Jane', 'Smith', '1992-11-23', '555-0102', 'jane.smith@email.com');

INSERT INTO Doctors (first_name, last_name, email, specialization_id, license_number) VALUES
('Alice', 'Brown', 'alice.brown@clinic.com', (SELECT specialization_id FROM Specializations WHERE specialization_name = 'General Practice'), 'GP12345'),
('Bob', 'Green', 'bob.green@clinic.com', (SELECT specialization_id FROM Specializations WHERE specialization_name = 'Cardiology'), 'CARD54321');

INSERT INTO Appointments (patient_id, doctor_id, service_id, appointment_datetime, reason_for_visit) VALUES
(
    (SELECT patient_id FROM Patients WHERE email = 'john.doe@email.com'),
    (SELECT doctor_id FROM Doctors WHERE email = 'alice.brown@clinic.com'),
    (SELECT service_id FROM Services WHERE service_name = 'General Consultation'),
    '2024-08-15 10:00:00',
    'Annual check-up'
),
(
    (SELECT patient_id FROM Patients WHERE email = 'jane.smith@email.com'),
    (SELECT doctor_id FROM Doctors WHERE email = 'bob.green@clinic.com'),
    (SELECT service_id FROM Services WHERE service_name = 'ECG Test'),
    '2024-08-16 14:30:00',
    'Heart palpitation concerns'
);
*/

SELECT '-- Database schema created successfully --' AS Status;