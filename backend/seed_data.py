import asyncio
import sys
from sqlalchemy.orm import Session
from app.db.session import SessionLocal, engine
from app.models.user import User, UserRole, Company
from app.core.security import get_password_hash
import uuid

def seed_database():
    db = SessionLocal()
    
    try:
        # Check if data already exists
        existing_companies = db.query(Company).count()
        if existing_companies > 0:
            print(f"Database already has {existing_companies} companies. Skipping seed.")
            return
        
        # Create Companies
        companies_data = [
            {
                "name": "TechCorp Global",
                "contact_email": "contact@techcorp.com",
                "contact_phone": "+1-555-0101",
                "address": "123 Tech Street, San Francisco, CA 94105"
            },
            {
                "name": "MediHealth Services",
                "contact_email": "admin@medihealth.com",
                "contact_phone": "+1-555-0202",
                "address": "456 Medical Plaza, Boston, MA 02115"
            },
            {
                "name": "Global Finance Inc",
                "contact_email": "info@globalfinance.com",
                "contact_phone": "+1-555-0303",
                "address": "789 Wall Street, New York, NY 10005"
            },
            {
                "name": "EduLearn Platform",
                "contact_email": "support@edulearn.com",
                "contact_phone": "+1-555-0404",
                "address": "321 Education Ave, Austin, TX 78701"
            },
            {
                "name": "RetailMax Corporation",
                "contact_email": "hr@retailmax.com",
                "contact_phone": "+1-555-0505",
                "address": "654 Commerce Blvd, Seattle, WA 98101"
            }
        ]
        
        companies = []
        for company_data in companies_data:
            company = Company(**company_data)
            db.add(company)
            companies.append(company)
        
        db.flush()  # Get company IDs
        print(f"✓ Created {len(companies)} companies")
        
        # Create Translators
        translators_data = [
            {
                "email": "maria.garcia@translator.com",
                "name": "Maria Garcia",
                "languages": ["SPANISH", "FRENCH"],
                "hourly_rate": "$45/hour",
                "is_available": True
            },
            {
                "email": "jean.dupont@translator.com",
                "name": "Jean Dupont",
                "languages": ["FRENCH"],
                "hourly_rate": "$50/hour",
                "is_available": True
            },
            {
                "email": "hans.mueller@translator.com",
                "name": "Hans Mueller",
                "languages": ["GERMAN"],
                "hourly_rate": "$48/hour",
                "is_available": True
            },
            {
                "email": "carmen.rodriguez@translator.com",
                "name": "Carmen Rodriguez",
                "languages": ["SPANISH"],
                "hourly_rate": "$42/hour",
                "is_available": True
            },
            {
                "email": "klaus.schmidt@translator.com",
                "name": "Klaus Schmidt",
                "languages": ["GERMAN", "FRENCH"],
                "hourly_rate": "$55/hour",
                "is_available": True
            },
            {
                "email": "isabelle.martin@translator.com",
                "name": "Isabelle Martin",
                "languages": ["FRENCH", "SPANISH"],
                "hourly_rate": "$47/hour",
                "is_available": False
            },
            {
                "email": "diego.sanchez@translator.com",
                "name": "Diego Sanchez",
                "languages": ["SPANISH"],
                "hourly_rate": "$40/hour",
                "is_available": True
            },
            {
                "email": "petra.wagner@translator.com",
                "name": "Petra Wagner",
                "languages": ["GERMAN"],
                "hourly_rate": "$52/hour",
                "is_available": True
            }
        ]
        
        translators = []
        for translator_data in translators_data:
            translator = User(
                id=uuid.uuid4(),
                email=translator_data["email"],
                name=translator_data["name"],
                hashed_password=get_password_hash("password123"),
                role=UserRole.TRANSLATOR,
                languages=translator_data["languages"],
                hourly_rate=translator_data["hourly_rate"],
                is_available=translator_data["is_available"]
            )
            db.add(translator)
            translators.append(translator)
        
        print(f"✓ Created {len(translators)} translators")
        
        # Create Employees for each company
        employees_data = [
            # TechCorp Global
            [
                {"email": "john.smith@techcorp.com", "name": "John Smith"},
                {"email": "sarah.johnson@techcorp.com", "name": "Sarah Johnson"},
                {"email": "mike.chen@techcorp.com", "name": "Mike Chen"},
            ],
            # MediHealth Services
            [
                {"email": "dr.emily.brown@medihealth.com", "name": "Dr. Emily Brown"},
                {"email": "nurse.david.lee@medihealth.com", "name": "David Lee"},
            ],
            # Global Finance Inc
            [
                {"email": "robert.wilson@globalfinance.com", "name": "Robert Wilson"},
                {"email": "jennifer.davis@globalfinance.com", "name": "Jennifer Davis"},
                {"email": "thomas.moore@globalfinance.com", "name": "Thomas Moore"},
                {"email": "lisa.taylor@globalfinance.com", "name": "Lisa Taylor"},
            ],
            # EduLearn Platform
            [
                {"email": "prof.james.white@edulearn.com", "name": "Prof. James White"},
                {"email": "amanda.harris@edulearn.com", "name": "Amanda Harris"},
            ],
            # RetailMax Corporation
            [
                {"email": "manager.kevin.clark@retailmax.com", "name": "Kevin Clark"},
                {"email": "susan.lewis@retailmax.com", "name": "Susan Lewis"},
                {"email": "daniel.walker@retailmax.com", "name": "Daniel Walker"},
            ]
        ]
        
        # Create Company Admins
        company_admins_data = [
            {"email": "admin@techcorp.com", "name": "Admin TechCorp"},
            {"email": "admin@medihealth.com", "name": "Admin MediHealth"},
            {"email": "admin@globalfinance.com", "name": "Admin GlobalFinance"},
            {"email": "admin@edulearn.com", "name": "Admin EduLearn"},
            {"email": "admin@retailmax.com", "name": "Admin RetailMax"},
        ]
        
        total_employees = 0
        total_admins = 0
        
        for i, company in enumerate(companies):
            # Create company admin
            admin = User(
                id=uuid.uuid4(),
                email=company_admins_data[i]["email"],
                name=company_admins_data[i]["name"],
                hashed_password=get_password_hash("password123"),
                role=UserRole.COMPANY_ADMIN,
                company_id=company.id
            )
            db.add(admin)
            total_admins += 1
            
            # Create employees
            for emp_data in employees_data[i]:
                employee = User(
                    id=uuid.uuid4(),
                    email=emp_data["email"],
                    name=emp_data["name"],
                    hashed_password=get_password_hash("password123"),
                    role=UserRole.EMPLOYEE,
                    company_id=company.id
                )
                db.add(employee)
                total_employees += 1
        
        print(f"✓ Created {total_admins} company admins")
        print(f"✓ Created {total_employees} employees")
        
        db.commit()
        
        print("\n=== Seed Data Summary ===")
        print(f"Companies: {len(companies)}")
        print(f"Translators: {len(translators)}")
        print(f"Company Admins: {total_admins}")
        print(f"Employees: {total_employees}")
        print(f"\nTotal Users: {len(translators) + total_admins + total_employees}")
        print("\nAll users have password: password123")
        
        print("\n=== Sample Login Credentials ===")
        print("\nTranslators:")
        for i, t in enumerate(translators[:3], 1):
            langs = ", ".join(t.languages)
            print(f"  {i}. {t.email} ({langs})")
        
        print("\nCompany Admins:")
        for i, admin in enumerate(company_admins_data[:3], 1):
            print(f"  {i}. {admin['email']} - {companies_data[i-1]['name']}")
        
        print("\nEmployees:")
        print(f"  1. {employees_data[0][0]['email']} - TechCorp Global")
        print(f"  2. {employees_data[1][0]['email']} - MediHealth Services")
        print(f"  3. {employees_data[2][0]['email']} - Global Finance Inc")
        
    except Exception as e:
        print(f"Error seeding database: {e}")
        db.rollback()
        raise
    finally:
        db.close()

if __name__ == "__main__":
    print("Starting database seed...\n")
    seed_database()
    print("\n✓ Database seeded successfully!")
