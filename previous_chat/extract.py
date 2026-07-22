import sqlite3
import json

db_path = r"c:\Users\joshu\OneDrive\Documents\Coding\Expense Tracker\previous_chat\8c29ec6f-cc82-45cd-82e6-24cf05e7519a.db"
conn = sqlite3.connect(db_path)
cursor = conn.cursor()

try:
    cursor.execute("SELECT step_payload FROM steps WHERE step_payload IS NOT NULL")
    for row in cursor.fetchall():
        payload = row[0]
        try:
            text = payload.decode('utf-8', errors='ignore')
            if 'implementation_plan.md' in text or 'task.md' in text:
                print("--- Found Reference ---")
                
                # Let's try to extract lines that look like markdown
                lines = text.split('\n')
                in_md = False
                for i, line in enumerate(lines):
                    if 'implementation_plan.md' in line or 'task.md' in line or '##' in line or '# ' in line or '- [' in line:
                        print(line)
        except Exception as e:
            pass
except Exception as e:
    print("Error:", e)
finally:
    conn.close()
