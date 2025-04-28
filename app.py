from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from database import execute_procedure, execute_query, test_db_connection

app = Flask(__name__)
app.secret_key = "dev_key"

@app.route('/')
def index():
    return render_template('index.html', db_connected=test_db_connection())

def handle_procedure(procedure_name, form_data, param_names, redirect_route):
    try:
        params = []
        for name in param_names:
            value = form_data.get(name)
            if value == 'TRUE':
                value = True
            elif not value:
                value = None
            params.append(value)
        
        execute_procedure(procedure_name, tuple(params))
        flash('Success', 'success')
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
    
    return redirect(url_for(redirect_route))

@app.route('/procedures/add_airplane', methods=['GET', 'POST'])
def add_airplane():
    if request.method == 'POST':
        params = ['airline_id', 'tail_num', 'seat_capacity', 'speed', 
                 'location_id', 'plane_type', 'maintained', 'model', 'neo']
        return handle_procedure('add_airplane', request.form, params, 'add_airplane')
    
    airlines = execute_query("SELECT DISTINCT airlineID FROM airline")
    return render_template('procedures/add_airplane.html', airlines=airlines)

@app.route('/procedures/add_airport', methods=['GET', 'POST'])
def add_airport():
    if request.method == 'POST':
        params = ['airport_id', 'airport_name', 'city', 'state', 'country', 'location_id']
        return handle_procedure('add_airport', request.form, params, 'add_airport')
    
    return render_template('procedures/add_airport.html')

@app.route('/procedures/add_person', methods=['GET', 'POST'])
def add_person():
    if request.method == 'POST':
        params = ['person_id', 'first_name', 'last_name', 'location_id', 
                 'tax_id', 'experience', 'miles', 'funds']
        return handle_procedure('add_person', request.form, params, 'add_person')
    
    locations = execute_query("SELECT locationID FROM location")
    return render_template('procedures/add_person.html', locations=locations)

@app.route('/procedures/grant_revoke_license', methods=['GET', 'POST'])
def grant_revoke_license():
    if request.method == 'POST':
        return handle_procedure('grant_or_revoke_pilot_license', 
                              request.form, ['person_id', 'license'], 'grant_revoke_license')
    
    pilots = execute_query("SELECT personID FROM pilot")
    license_types = ["Boeing", "Airbus", "general"]
    return render_template('procedures/grant_revoke_license.html', pilots=pilots, license_types=license_types)

@app.route('/procedures/offer_flight', methods=['GET', 'POST'])
def offer_flight():
    if request.method == 'POST':
        params = ['flight_id', 'route_id', 'support_airline', 'support_tail', 
                 'progress', 'next_time', 'cost']
        return handle_procedure('offer_flight', request.form, params, 'offer_flight')
    
    routes = execute_query("SELECT routeID FROM route")
    airlines = execute_query("SELECT DISTINCT airlineID FROM airline")
    airplanes = execute_query("SELECT airlineID, tail_num FROM airplane")
    return render_template('procedures/offer_flight.html', 
                         routes=routes, airlines=airlines, airplanes=airplanes)

@app.route('/procedures/flight_landing', methods=['GET', 'POST'])
def flight_landing():
    if request.method == 'POST':
        return handle_procedure('flight_landing', request.form, ['flight_id'], 'flight_landing')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'in_flight'")
    return render_template('procedures/flight_landing.html', flights=flights)

@app.route('/procedures/flight_takeoff', methods=['GET', 'POST'])
def flight_takeoff():
    if request.method == 'POST':
        return handle_procedure('flight_takeoff', request.form, ['flight_id'], 'flight_takeoff')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/flight_takeoff.html', flights=flights)

@app.route('/procedures/passengers_board', methods=['GET', 'POST'])
def passengers_board():
    if request.method == 'POST':
        return handle_procedure('passengers_board', request.form, ['flight_id'], 'passengers_board')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/passengers_board.html', flights=flights)

@app.route('/procedures/passengers_disembark', methods=['GET', 'POST'])
def passengers_disembark():
    if request.method == 'POST':
        return handle_procedure('passengers_disembark', request.form, ['flight_id'], 'passengers_disembark')
    
    flights = execute_query("SELECT flightID FROM flight WHERE airplane_status = 'on_ground'")
    return render_template('procedures/passengers_disembark.html', flights=flights)

@app.route('/procedures/assign_pilot', methods=['GET', 'POST'])
def assign_pilot():
    if request.method == 'POST':
        return handle_procedure('assign_pilot', request.form, ['flight_id', 'person_id'], 'assign_pilot')
    
    flights = execute_query("SELECT flightID FROM flight")
    pilots = execute_query("SELECT personID FROM pilot")
    return render_template('procedures/assign_pilot.html', flights=flights, pilots=pilots)

@app.route('/procedures/recycle_crew', methods=['GET', 'POST'])
def recycle_crew():
    if request.method == 'POST':
        return handle_procedure('recycle_crew', request.form, ['flight_id'], 'recycle_crew')
    
    flights = execute_query("SELECT flightID FROM flight")
    return render_template('procedures/recycle_crew.html', flights=flights)

@app.route('/procedures/retire_flight', methods=['GET', 'POST'])
def retire_flight():
    if request.method == 'POST':
        return handle_procedure('retire_flight', request.form, ['flight_id'], 'retire_flight')
    
    flights = execute_query("SELECT flightID FROM flight")
    return render_template('procedures/retire_flight.html', flights=flights)

@app.route('/procedures/simulation_cycle', methods=['GET', 'POST'])
def simulation_cycle():
    if request.method == 'POST':
        return handle_procedure('simulation_cycle', request.form, [], 'simulation_cycle')
    
    return render_template('procedures/simulation_cycle.html')

@app.route('/views/flights_in_air')
def flights_in_air():
    try:
        results = execute_query("SELECT * FROM flights_in_the_air")
        return render_template('views/flights_in_air.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/flights_in_air.html', results=[])

@app.route('/views/flights_on_ground')
def flights_on_ground():
    try:
        results = execute_query("SELECT * FROM flights_on_the_ground")
        return render_template('views/flights_on_ground.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/flights_on_ground.html', results=[])

@app.route('/views/people_in_air')
def people_in_air():
    try:
        results = execute_query("SELECT * FROM people_in_the_air")
        for result in results:
            for field in ['airplane_list', 'flight_list', 'person_list']:
                if field in result and result[field] is not None:
                    result[field] = result[field].split(',')
                else:
                    result[field] = []
                    
        return render_template('views/people_in_air.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/people_in_air.html', results=[])

@app.route('/views/people_on_ground')
def people_on_ground():
    try:
        results = execute_query("SELECT * FROM people_on_the_ground")
        return render_template('views/people_on_ground.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/people_on_ground.html', results=[])

@app.route('/views/route_summary')
def route_summary():
    try:
        results = execute_query("SELECT * FROM route_summary")
        return render_template('views/route_summary.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/route_summary.html', results=[])

@app.route('/views/alternative_airports')
def alternative_airports():
    try:
        results = execute_query("SELECT * FROM alternative_airports")
        for result in results:
            if 'airport_name_list' in result and result['airport_name_list'] is not None:
                result['airport_names_list'] = result['airport_name_list']
            
            if 'airport_code_list' in result and result['airport_code_list'] is not None:
                result['airport_code_list'] = result['airport_code_list'].split(',')
            else:
                result['airport_code_list'] = []
                
            if 'airport_names_list' in result and result['airport_names_list'] is not None:
                result['airport_names_list'] = result['airport_names_list'].split(',')
            elif 'airport_name_list' in result and result['airport_name_list'] is not None:
                result['airport_names_list'] = result['airport_name_list'].split(',')
            else:
                result['airport_names_list'] = []
                
        return render_template('views/alternative_airports.html', results=results)
    except Exception as e:
        flash(f'Error: {str(e)}', 'danger')
        return render_template('views/alternative_airports.html', results=[])

@app.route('/api/get_tails_for_airline/<airline_id>')
def get_tails_for_airline(airline_id):
    try:
        tails = execute_query("SELECT tail_num FROM airplane WHERE airlineID = %s", (airline_id,))
        return jsonify(tails)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001, debug=True)