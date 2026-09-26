import os
import secrets
from datetime import timedelta
from psycopg2 import pool
from flask import Flask, render_template, request, session, g, redirect, url_for
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = os.environ.get("SECRET_KEY", "flightops-dev-secret-key-3f8a1e9c2b4d")
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=7)

# Initialize database connection pool
try:
    db_pool = pool.SimpleConnectionPool(
        1, 20,
        dbname=os.environ.get("POSTGRES_DB", "flightops"),
        user=os.environ.get("POSTGRES_USER", "flightops"),
        password=os.environ.get("POSTGRES_PASSWORD"),
        host=os.environ.get("POSTGRES_HOST", "localhost"),
        port=os.environ.get("POSTGRES_PORT", "5432"),
    )
except Exception as e:
    print("Database connection failed:", e)
    db_pool = None

def get_db():
    if 'db' not in g:
        g.db = db_pool.getconn()
    return g.db

@app.teardown_appcontext
def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db_pool.putconn(db)

@app.route("/", methods=["GET", "POST"])
def sign_up_page():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        email = request.form.get("email")
        
        db = get_db()
        cursor = db.cursor()
        try:
            cursor.execute(
                "INSERT INTO users (name, password, email) VALUES (%s, %s, %s) RETURNING id",
                (username, password, email)
            )
            user_id = cursor.fetchone()[0]
            db.commit()
            session.permanent = True
            session['user_id'] = user_id
            return redirect(url_for('shop'))
        except Exception:
            db.rollback()
            return render_template("wrong.html")
        finally:
            cursor.close()
            
    return render_template("sign-up.html")

@app.route("/sign-in", methods=["GET", "POST"])
def sign_in_page():
    if request.method == "POST":
        username = request.form.get("username")
        password = request.form.get("password")
        
        db = get_db()
        cursor = db.cursor()
        cursor.execute("SELECT id FROM users WHERE name = %s AND password = %s", (username, password))
        user = cursor.fetchone()
        cursor.close()
        
        if user:
            session.permanent = True
            session['user_id'] = user[0]
            return redirect(url_for('shop'))
        else:
            return render_template("wrong.html")
            
    return render_template("sign-in.html")

@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for('sign_in_page'))

@app.route("/shop", methods=["GET", "POST"])
def shop():
    if 'user_id' not in session:
        return redirect(url_for('sign_in_page'))
        
    db = get_db()
    cursor = db.cursor()
    
    # Get all states for dropdown selection
    cursor.execute("SELECT state_code, state_name FROM states ORDER BY state_name ASC")
    states = cursor.fetchall()

    # Get user name
    cursor.execute("SELECT name FROM users WHERE id = %s", (session['user_id'],))
    name_res = cursor.fetchone()
    name = name_res[0] if name_res else "Guest"
    
    # Get user flights
    cursor.execute("""
        SELECT s1.state_name, s2.state_name, t.departure_time, t.arrival_time, t.ticket_number 
        FROM tickets t
        JOIN states s1 ON t.departure_state_id = s1.id
        JOIN states s2 ON t.arrival_state_id = s2.id
        WHERE t.user_id = %s
    """, (session['user_id'],))
    flights = cursor.fetchall()
    cursor.close()
    
    return render_template("shop.html", name=name, flights=flights, states=states)

@app.route("/ticket", methods=["POST"])
def ticket():
    if 'user_id' not in session:
        return redirect(url_for('sign_in_page'))
        
    db = get_db()
    cursor = db.cursor()
    
    buy_dep = request.form.get("buy-departure")
    buy_dest = request.form.get("buy-destination")
    
    if buy_dep and buy_dest:
        dep_val = buy_dep.strip()
        dest_val = buy_dest.strip()
        cursor.execute("""
            SELECT f.id, s1.state_name, s2.state_name, f.departure_time, f.arrival_time, f.price
            FROM flights f
            JOIN states s1 ON f.departure_state_id = s1.id
            JOIN states s2 ON f.arrival_state_id = s2.id
            WHERE (LOWER(s1.state_name) = LOWER(%s) OR UPPER(s1.state_code) = UPPER(%s))
              AND (LOWER(s2.state_name) = LOWER(%s) OR UPPER(s2.state_code) = UPPER(%s))
            LIMIT 1
        """, (dep_val, dep_val, dest_val, dest_val))
        flight = cursor.fetchone()
        cursor.close()
        
        if not flight:
            return render_template("wrong.html")
            
        available_flights = {
            "departure": flight[1],
            "destination": flight[2],
            "departure_time": flight[3],
            "arrival_time": flight[4],
            "price": flight[5]
        }
        return render_template("ticket.html", action="buy", available_flights=available_flights)
        
    del_dep = request.form.get("delete-departure")
    del_dest = request.form.get("delete-destination")
    
    if del_dep and del_dest:
        dep_val = del_dep.strip()
        dest_val = del_dest.strip()
        cursor.execute("""
            SELECT t.id, t.ticket_number, s1.state_name, s2.state_name, t.departure_time, t.arrival_time
            FROM tickets t
            JOIN states s1 ON t.departure_state_id = s1.id
            JOIN states s2 ON t.arrival_state_id = s2.id
            WHERE t.user_id = %s
              AND (LOWER(s1.state_name) = LOWER(%s) OR UPPER(s1.state_code) = UPPER(%s))
              AND (LOWER(s2.state_name) = LOWER(%s) OR UPPER(s2.state_code) = UPPER(%s))
            LIMIT 1
        """, (session['user_id'], dep_val, dep_val, dest_val, dest_val))
        flight = cursor.fetchall()
        cursor.close()
        if not flight:
            return render_template("wrong.html")
        return render_template("ticket.html", action="delete", flight=flight)
        
    cursor.close()
    return redirect(url_for('shop'))

@app.route("/payment", methods=["POST"])
def payment():
    if 'user_id' not in session:
        return redirect(url_for('sign_in_page'))
        
    # Store flight details in session to mock a real payment flow
    session['pending_ticket'] = request.form.to_dict()
    return render_template("payment.html")

@app.route("/success", methods=["POST"])
def success():
    if 'user_id' not in session or 'pending_ticket' not in session:
        return redirect(url_for('shop'))
        
    pending = session.pop('pending_ticket')
    ticket_id = secrets.token_hex(4).upper()
    
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("SELECT id FROM states WHERE LOWER(state_name) = LOWER(%s) OR UPPER(state_code) = UPPER(%s)", (pending['departure'], pending['departure']))
        dep_id = cursor.fetchone()[0]
        cursor.execute("SELECT id FROM states WHERE LOWER(state_name) = LOWER(%s) OR UPPER(state_code) = UPPER(%s)", (pending['destination'], pending['destination']))
        dest_id = cursor.fetchone()[0]
        
        cursor.execute("""
            INSERT INTO tickets (ticket_number, departure_state_id, arrival_state_id, departure_time, arrival_time, ticket_price, user_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """, (ticket_id, dep_id, dest_id, pending['departure_time'], pending['arrival_time'], pending['price'], session['user_id']))
        db.commit()
        return render_template("success.html", ticket_id=ticket_id)
    except Exception as e:
        db.rollback()
        return render_template("wrong.html")
    finally:
        cursor.close()

@app.route("/delete", methods=["POST"])
def delete():
    if 'user_id' not in session:
        return redirect(url_for('sign_in_page'))
        
    ticket_id = request.form.get("delete-ticket-id")
    if not ticket_id:
        return redirect(url_for('shop'))
        
    db = get_db()
    cursor = db.cursor()
    try:
        cursor.execute("DELETE FROM tickets WHERE ticket_number = %s AND user_id = %s", (ticket_id, session['user_id']))
        if cursor.rowcount > 0:
            db.commit()
            return render_template("delete.html")
        else:
            return render_template("wrong.html")
    except Exception:
        db.rollback()
        return render_template("wrong.html")
    finally:
        cursor.close()

if __name__ == "__main__":
    app.run(debug=True)