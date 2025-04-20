import os
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from database import execute_procedure, execute_query, test_db_connection

app = Flask(__name__)
app.secret_key = "a_secret_key_for_development"  # Static secret key for Flash messages

# Main Route
@app.route('/')
def index():
    db_connected = test_db_connection()
    return render_template('index.html', db_connected=db_connected)

# Add Airplane Route
@app.route('/procedures/add_airplane', methods=['GET', 'POST'])
def add_airplane():
    if request.method == 'POST':
        # Get form data
        airline_id = request.form.get('airline_id')
        tail_num = request.form.get('tail_num')
        seat_capacity = request.form.get('seat_capacity')
        speed = request.form.get('speed')
        location_id = request.form.get('location_id')
        plane_type = request.form.get('plane_type')
        maintained = True if request.form.get('maintained') == 'TRUE' else None
        model = request.form.get('model') or None
        neo = True if request.form.get('neo') == 'TRUE' else None
        
        try:
            # Call stored procedure
            execute_procedure('add_airplane', 
                             (airline_id, tail_num, seat_capacity, speed, 
                              location_id, plane_type, maintained, model, neo))
            flash('Airplane added successfully!', 'success')
            return redirect(url_for('add_airplane'))
        except Exception as e:
            flash(f'Error adding airplane: {str(e)}', 'danger')
    
    # Get airlines for dropdown
    airlines = execute_query("SELECT DISTINCT airlineID FROM airline")
    return render_template('procedures/add_airplane.html', airlines=airlines)

# Add Airport Route
@app.route('/procedures/add_airport', methods=['GET', 'POST'])
def add_airport():
    if request.method == 'POST':
        # Get form data
        airport_id = request.form.get('airport_id')
        airport_name = request.form.get('airport_name')
        city = request.form.get('city')
        state = request.form.get('state')
        country = request.form.get('country')
        location_id = request.form.get('location_id')
        
        try:
            # Call stored procedure
            execute_procedure('add_airport', 
                             (airport_id, airport_name, city, state, country, location_id))
            flash('Airport added successfully!', 'success')
            return redirect(url_for('add_airport'))
        except Exception as e:
            flash(f'Error adding airport: {str(e)}', 'danger')
    
    return render_template('procedures/add_airport.html')

# Add Person Route
@app.route('/procedures/add_person', methods=['GET', 'POST'])
def add_person():
    if request.method == 'POST':
        # Get form data
        person_id = request.form.get('person_id')
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        location_id = request.form.get('location_id')
        tax_id = request.form.get('tax_id') or None
        experience = request.form.get('experience') or None
        miles = request.form.get('miles') or None
        funds = request.form.get('funds') or None
        
        try:
            # Call stored procedure
            execute_procedure('add_person', 
                             (person_id, first_name, last_name, location_id, 
                              tax_id, experience, miles, funds))
            flash('Person added successfully!', 'success')
            return redirect(url_for('add_person'))
        except Exception as e:
            flash(f'Error adding person: {str(e)}', 'danger')
    
    # Get locations for dropdown
    locations = execute_query("SELECT locationID FROM location")
    return render_template('procedures/add_person.html', locations=locations)

# Grant or Revoke Pilot License Route
@app.route('/procedures/grant_revoke_license', methods=['GET', 'POST'])
def grant_revoke_license():
    if request.method == 'POST':
        person_id = request.form.get('person_id')
        license_type = request.form.get('license')
        
        try:
            execute_procedure('grant_or_revoke_pilot_license', (person_id, license_type))
            flash('Pilot license updated successfully!', 'success')
            return redirect(url_for('grant_revoke_license'))
        except Exception as e:
            flash(f'Error updating pilot license: {str(e)}', 'danger')
    
    pilots = execute_query("SELECT personID FROM pilot")
    license_types = ["Boeing", "Airbus", "general"]
    return render_template('procedures/grant_revoke_license.html', pilots=pilots, license_types=license_types)

# Offer Flight Route
@app.route('/procedures/offer_flight', methods=['GET', 'POST'])
def offer_flight():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        route_id = request.form.get('route_id')
        support_airline = request.form.get('support_airline')
        support_tail = request.form.get('support_tail')
        progress = request.form.get('progress')
        next_time = request.form.get('next_time')
        cost = request.form.get('cost')
        
        try:
            execute_procedure('offer_flight', 
                             (flight_id, route_id, support_airline, 
                              support_tail, progress, next_time, cost))
            flash('Flight offered successfully!', 'success')
            return redirect(url_for('offer_flight'))
        except Exception as e:
            flash(f'Error offering flight: {str(e)}', 'danger')
    
    routes = execute_query("SELECT routeID FROM route")
    airlines = execute_query("SELECT DISTINCT airlineID FROM airline")
    airplanes = execute_query("SELECT airlineID, tail_num FROM airplane")
    return render_template('procedures/offer_flight.html', 
                          routes=routes, airlines=airlines, airplanes=airplanes)

# Flight Landing Route
@app.route('/procedures/flight_landing', methods=['GET', 'POST'])
def flight_landing():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('flight_landing', (flight_id,))
            flash('Flight landed successfully!', 'success')
            return redirect(url_for('flight_landing'))
        except Exception as e:
            flash(f'Error landing flight: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'in_flight'")
    return render_template('procedures/flight_landing.html', flights=flights)

# Flight Takeoff Route
@app.route('/procedures/flight_takeoff', methods=['GET', 'POST'])
def flight_takeoff():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('flight_takeoff', (flight_id,))
            flash('Flight took off successfully!', 'success')
            return redirect(url_for('flight_takeoff'))
        except Exception as e:
            flash(f'Error during takeoff: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/flight_takeoff.html', flights=flights)

# Passengers Board Route
@app.route('/procedures/passengers_board', methods=['GET', 'POST'])
def passengers_board():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('passengers_board', (flight_id,))
            flash('Passengers boarded successfully!', 'success')
            return redirect(url_for('passengers_board'))
        except Exception as e:
            flash(f'Error boarding passengers: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/passengers_board.html', flights=flights)

# Passengers Disembark Route
@app.route('/procedures/passengers_disembark', methods=['GET', 'POST'])
def passengers_disembark():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('passengers_disembark', (flight_id,))
            flash('Passengers disembarked successfully!', 'success')
            return redirect(url_for('passengers_disembark'))
        except Exception as e:
            flash(f'Error disembarking passengers: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/passengers_disembark.html', flights=flights)

# Assign Pilot Route
@app.route('/procedures/assign_pilot', methods=['GET', 'POST'])
def assign_pilot():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        person_id = request.form.get('person_id')
        
        try:
            execute_procedure('assign_pilot', (flight_id, person_id))
            flash('Pilot assigned successfully!', 'success')
            return redirect(url_for('assign_pilot'))
        except Exception as e:
            flash(f'Error assigning pilot: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight")
    pilots = execute_query("SELECT personID FROM pilot")
    return render_template('procedures/assign_pilot.html', flights=flights, pilots=pilots)

# Recycle Crew Route
@app.route('/procedures/recycle_crew', methods=['GET', 'POST'])
def recycle_crew():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('recycle_crew', (flight_id,))
            flash('Crew recycled successfully!', 'success')
            return redirect(url_for('recycle_crew'))
        except Exception as e:
            flash(f'Error recycling crew: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight")
    return render_template('procedures/recycle_crew.html', flights=flights)

# Retire Flight Route
@app.route('/procedures/retire_flight', methods=['GET', 'POST'])
def retire_flight():
    if request.method == 'POST':
        flight_id = request.form.get('flight_id')
        
        try:
            execute_procedure('retire_flight', (flight_id,))
            flash('Flight retired successfully!', 'success')
            return redirect(url_for('retire_flight'))
        except Exception as e:
            flash(f'Error retiring flight: {str(e)}', 'danger')
    
    flights = execute_query("SELECT flightID FROM flight")
    return render_template('procedures/retire_flight.html', flights=flights)

# Simulation Cycle Route
@app.route('/procedures/simulation_cycle', methods=['GET', 'POST'])
def simulation_cycle():
    if request.method == 'POST':
        try:
            execute_procedure('simulation_cycle', ())
            flash('Simulation cycle completed successfully!', 'success')
            return redirect(url_for('simulation_cycle'))
        except Exception as e:
            flash(f'Error during simulation cycle: {str(e)}', 'danger')
    
    return render_template('procedures/simulation_cycle.html')

# View Routes
@app.route('/views/flights_in_air')
def flights_in_air():
    try:
        results = execute_query("SELECT * FROM flights_in_the_air")
        return render_template('views/flights_in_air.html', results=results)
    except Exception as e:
        flash(f'Error retrieving flights in air: {str(e)}', 'danger')
        return render_template('views/flights_in_air.html', results=[])

@app.route('/views/flights_on_ground')
def flights_on_ground():
    try:
        results = execute_query("SELECT * FROM flights_on_the_ground")
        return render_template('views/flights_on_ground.html', results=results)
    except Exception as e:
        flash(f'Error retrieving flights on ground: {str(e)}', 'danger')
        return render_template('views/flights_on_ground.html', results=[])

@app.route('/views/people_in_air')
def people_in_air():
    try:
        results = execute_query("SELECT * FROM people_in_the_air")
        return render_template('views/people_in_air.html', results=results)
    except Exception as e:
        flash(f'Error retrieving people in air: {str(e)}', 'danger')
        return render_template('views/people_in_air.html', results=[])

@app.route('/views/people_on_ground')
def people_on_ground():
    try:
        results = execute_query("SELECT * FROM people_on_the_ground")
        return render_template('views/people_on_ground.html', results=results)
    except Exception as e:
        flash(f'Error retrieving people on ground: {str(e)}', 'danger')
        return render_template('views/people_on_ground.html', results=[])

@app.route('/views/route_summary')
def route_summary():
    try:
        results = execute_query("SELECT * FROM route_summary")
        return render_template('views/route_summary.html', results=results)
    except Exception as e:
        flash(f'Error retrieving route summary: {str(e)}', 'danger')
        return render_template('views/route_summary.html', results=[])

@app.route('/views/alternative_airports')
def alternative_airports():
    try:
        results = execute_query("SELECT * FROM alternative_airports")
        return render_template('views/alternative_airports.html', results=results)
    except Exception as e:
        flash(f'Error retrieving alternative airports: {str(e)}', 'danger')
        return render_template('views/alternative_airports.html', results=[])

# API Routes for dropdowns
@app.route('/api/get_tails_for_airline/<airline_id>')
def get_tails_for_airline(airline_id):
    try:
        tails = execute_query(f"SELECT tail_num FROM airplane WHERE airlineID = '{airline_id}'")
        return jsonify(tails)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)