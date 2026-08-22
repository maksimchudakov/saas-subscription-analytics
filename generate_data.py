"""
Generates synthetic SaaS subscription data: customers and billing events.
Simulates ~2.5 years of activity with realistic patterns (seasonality,
plan-based churn differences, a churn spike after a simulated price change).
"""

import random
from datetime import date, timedelta
import pandas as pd
from faker import Faker

fake = Faker()
Faker.seed(42)
random.seed(42)

# --- Config ---
NUM_CUSTOMERS = 1500
START_DATE = date(2023, 1, 1)
END_DATE = date(2025, 6, 30)

PLANS = {
    "Basic": {"price": 29, "monthly_churn": 0.06},
    "Pro": {"price": 99, "monthly_churn": 0.035},
    "Enterprise": {"price": 499, "monthly_churn": 0.015},
}
SEGMENTS = ["SMB", "Mid-Market", "Enterprise"]
INDUSTRIES = ["Retail", "Healthcare", "Finance", "Education", "Technology", "Manufacturing"]

PRICE_HIKE_DATE = date(2024, 9, 1)  # simulated event: churn spikes right after

def random_date(start, end):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def weighted_signup_date():
    # more signups in Jan (budget resets) and Sep (back-to-business), fewer in Jul/Dec
    while True:
        d = random_date(START_DATE, END_DATE)
        weight = 1.3 if d.month in (1, 9) else 0.6 if d.month in (7, 12) else 1.0
        if random.random() < weight / 1.3:
            return d

def pick_plan(segment):
    if segment == "Enterprise":
        return random.choices(["Pro", "Enterprise"], weights=[0.2, 0.8])[0]
    if segment == "Mid-Market":
        return random.choices(["Basic", "Pro", "Enterprise"], weights=[0.2, 0.6, 0.2])[0]
    return random.choices(["Basic", "Pro"], weights=[0.7, 0.3])[0]

customers = []
events = []
event_id = 1

for i in range(1, NUM_CUSTOMERS + 1):
    customer_id = f"CUST{i:05d}"
    signup_date = weighted_signup_date()
    segment = random.choices(SEGMENTS, weights=[0.55, 0.30, 0.15])[0]
    plan = pick_plan(segment)

    customers.append({
        "customer_id": customer_id,
        "company_name": fake.company(),
        "industry": random.choice(INDUSTRIES),
        "country": fake.country(),
        "segment": segment,
        "signup_date": signup_date,
    })

    events.append({
        "event_id": event_id,
        "customer_id": customer_id,
        "event_date": signup_date,
        "event_type": "signup",
        "plan": plan,
        "mrr_amount": PLANS[plan]["price"],
    })
    event_id += 1

    # simulate the customer's lifecycle month by month after signup
    current_plan = plan
    current_date = signup_date
    active = True
    while active:
        current_date = current_date + timedelta(days=30)
        if current_date > END_DATE:
            break

        churn_prob = PLANS[current_plan]["monthly_churn"]
        # price hike bump: churn roughly doubles for ~2 months after the hike
        if PRICE_HIKE_DATE <= current_date <= PRICE_HIKE_DATE + timedelta(days=60):
            churn_prob *= 2.0

        roll = random.random()
        if roll < churn_prob:
            events.append({
                "event_id": event_id,
                "customer_id": customer_id,
                "event_date": current_date,
                "event_type": "cancel",
                "plan": current_plan,
                "mrr_amount": 0,
            })
            event_id += 1
            active = False

        elif roll < churn_prob + 0.02:  # upgrade
            plan_order = ["Basic", "Pro", "Enterprise"]
            idx = plan_order.index(current_plan)
            if idx < len(plan_order) - 1:
                current_plan = plan_order[idx + 1]
                events.append({
                    "event_id": event_id,
                    "customer_id": customer_id,
                    "event_date": current_date,
                    "event_type": "upgrade",
                    "plan": current_plan,
                    "mrr_amount": PLANS[current_plan]["price"],
                })
                event_id += 1

        elif roll < churn_prob + 0.03:  # downgrade
            plan_order = ["Basic", "Pro", "Enterprise"]
            idx = plan_order.index(current_plan)
            if idx > 0:
                current_plan = plan_order[idx - 1]
                events.append({
                    "event_id": event_id,
                    "customer_id": customer_id,
                    "event_date": current_date,
                    "event_type": "downgrade",
                    "plan": current_plan,
                    "mrr_amount": PLANS[current_plan]["price"],
                })
                event_id += 1

customers_df = pd.DataFrame(customers)
events_df = pd.DataFrame(events).sort_values(["customer_id", "event_date"])

customers_df.to_csv("customers.csv", index=False)
events_df.to_csv("subscription_events.csv", index=False)

print(f"Customers generated: {len(customers_df)}")
print(f"Events generated: {len(events_df)}")
print(f"Event type breakdown:\n{events_df['event_type'].value_counts()}")
