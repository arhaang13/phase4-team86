-- CS4400: Introduction to Database Systems: Monday, March 3, 2025
-- Simple Airline Management System Course Project Mechanics [TEMPLATE] (v0)
-- Views, Functions & Stored Procedures

/* This is a standard preamble for most of our scripts.  The intent is to establish
a consistent environment for the database behavior. */
set global transaction isolation level serializable;
set global SQL_MODE = 'ANSI,TRADITIONAL';
set names utf8mb4;
set SQL_SAFE_UPDATES = 0;

set @thisDatabase = 'flight_tracking';
use flight_tracking;
-- -----------------------------------------------------------------------------
-- stored procedures and views
-- -----------------------------------------------------------------------------
/* Standard Procedure: If one or more of the necessary conditions for a procedure to
be executed is false, then simply have the procedure halt execution without changing
the database state. Do NOT display any error messages, etc. */

-- [_] supporting functions, views and stored procedures
-- -----------------------------------------------------------------------------
/* Helpful library capabilities to simplify the implementation of the required
views and procedures. */
-- -----------------------------------------------------------------------------
drop function if exists leg_time;
delimiter //
create function leg_time (ip_distance integer, ip_speed integer)
	returns time reads sql data
begin
	declare total_time decimal(10,2);
    declare hours, minutes integer default 0;
    set total_time = ip_distance / ip_speed;
    set hours = truncate(total_time, 0);
    set minutes = truncate((total_time - hours) * 60, 0);
    return maketime(hours, minutes, 0);
end //
delimiter ;

-- [1] add_airplane()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airplane.  A new airplane must be sponsored
by an existing airline, and must have a unique tail number for that airline.
username.  An airplane must also have a non-zero seat capacity and speed. An airplane
might also have other factors depending on it's type, like the model and the engine.  
Finally, an airplane must have a new and database-wide unique location
since it will be used to carry passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airplane;
delimiter //
create procedure add_airplane (in ip_airlineID varchar(50), in ip_tail_num varchar(50),
	in ip_seat_capacity integer, in ip_speed integer, in ip_locationID varchar(50),
    in ip_plane_type varchar(100), in ip_maintenanced boolean, in ip_model varchar(50),
    in ip_neo boolean)
sp_main: begin

	-- Ensure that the plane type is valid: Boeing, Airbus, or neither
    -- Ensure that the type-specific attributes are accurate for the type
    -- Ensure that the airplane and location values are new and unique
    -- Add airplane and location into respective tables
    
    if (select count(*) from airplane 
        where airlineID = ip_airlineID and tail_num = ip_tail_num) > 0 then
		leave sp_main;
	end if;
    
    if ip_airlineID is null then
		leave sp_main;
	end if;

	if ip_seat_capacity <= 0 or ip_speed <= 0 then
		leave sp_main;
	end if;
    
    if ip_plane_type != 'boeing' and ip_plane_type != 'airbus' and ip_plane_type is not null then
		leave sp_main;
	end if;

	if ip_plane_type = 'boeing' and (ip_maintenanced is null or ip_model is null) then
		leave sp_main;
	end if;

	if ip_plane_type = 'airbus' and ip_neo is null then
		leave sp_main;
	end if;

	if (select count(*) from location where locationID = ip_locationID) = 0 then
		insert into location values (ip_locationID);
	end if;

	insert into airplane (airlineID, tail_num, seat_capacity, speed, locationID, 
						 plane_type, maintenanced, model, neo)
	values (ip_airlineID, ip_tail_num, ip_seat_capacity, ip_speed, ip_locationID,
		   ip_plane_type, 
		   case when ip_plane_type = 'boeing' then ip_maintenanced else null end,
		   case when ip_plane_type = 'boeing' then ip_model else null end,
		   case when ip_plane_type = 'airbus' then ip_neo else null end);

end //
delimiter ;

-- [2] add_airport()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new airport.  A new airport must have a unique
identifier along with a new and database-wide unique location if it will be used
to support airplane takeoffs and landings.  An airport may have a longer, more
descriptive name.  An airport must also have a city, state, and country designation. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_airport;
delimiter //
create procedure add_airport (in ip_airportID char(3), in ip_airport_name varchar(200),
    in ip_city varchar(100), in ip_state varchar(100), in ip_country char(3), in ip_locationID varchar(50))
sp_main: begin

	-- Ensure that the airport and location values are new and unique
    -- Add airport and location into respective tables
	if (select count(*) from airport where airportID = ip_airportID) != 0 then leave sp_main; end if;
    
	if (select count(*) from location where locationID = ip_locationID) >= 1 then
    leave sp_main;
    end if;
    
    insert into location (locationID) value (ip_locationID);
    
    if ip_city is null then leave sp_main; end if;
    if ip_state is null then leave sp_main; end if;
    if ip_country is null then leave sp_main; end if;
    
	insert into airport (airportID, airport_name, city, state, country, locationID)
	values (ip_airportID, ip_airport_name, ip_city, ip_state, ip_country, ip_locationID);


end //
delimiter ;

-- [3] add_person()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new person.  A new person must reference a unique
identifier along with a database-wide unique location used to determine where the
person is currently located: either at an airport, or on an airplane, at any given
time.  A person must have a first name, and might also have a last name.

A person can hold a pilot role or a passenger role (exclusively).  As a pilot,
a person must have a tax identifier to receive pay, and an experience level.  As a
passenger, a person will have some amount of frequent flyer miles, along with a
certain amount of funds needed to purchase tickets for flights. */
-- -----------------------------------------------------------------------------
drop procedure if exists add_person;
delimiter //
create procedure add_person (in ip_personID varchar(50), in ip_first_name varchar(100),
    in ip_last_name varchar(100), in ip_locationID varchar(50), in ip_taxID varchar(50),
    in ip_experience integer, in ip_miles integer, in ip_funds integer)
sp_main: begin

	-- Ensure that the location is valid
    -- Ensure that the persion ID is unique
    -- Ensure that the person is a pilot or passenger
    -- Add them to the person table as well as the table of their respective role

	if ip_first_name is null or ip_locationID is null then
		leave sp_main;
	end if;
    
	if ip_personID not in (select personID from person) and ip_locationID in (select locationID from location) then
		insert into person (personID, first_name, last_name, locationID)
		values (ip_personID, ip_first_name, ip_last_name, ip_locationID);
		
		if ip_taxID is null and ip_experience is null and ip_funds is not null and ip_miles is not null then
			insert into passenger (personID, miles, funds)
			values (ip_personID, ip_miles, ip_funds);
		end if;
		
		if ip_taxID is not null and ip_experience is not null and ip_funds is null and ip_miles is null then
			insert into pilot (personID, taxID, experience, commanding_flight)
			values (ip_personID, ip_taxID, ip_experience, NULL);
		end if;
    end if;


end //
delimiter ;

-- [4] grant_or_revoke_pilot_license()
-- -----------------------------------------------------------------------------
/* This stored procedure inverts the status of a pilot license.  If the license
doesn't exist, it must be created; and, if it aready exists, then it must be removed. */
-- -----------------------------------------------------------------------------
drop procedure if exists grant_or_revoke_pilot_license;
delimiter //
create procedure grant_or_revoke_pilot_license (in ip_personID varchar(50), in ip_license varchar(100))
sp_main: begin

	-- Ensure that the person is a valid pilot
    -- If license exists, delete it, otherwise add the license
    
    if ip_personID not in (select personID from pilot) then
		leave sp_main;
	end if;
	if (select count(*) from pilot_licenses where personID = ip_personID and license = ip_license) > 0 then
        delete from pilot_licenses 
        where personID = ip_personID and license = ip_license;
    else
        insert into pilot_licenses (personID, license)
        values (ip_personID, ip_license);
    end if;


end //
delimiter ;

-- [5] offer_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure creates a new flight.  The flight can be defined before
an airplane has been assigned for support, but it must have a valid route.  And
the airplane, if designated, must not be in use by another flight.  The flight
can be started at any valid location along the route except for the final stop,
and it will begin on the ground.  You must also include when the flight will
takeoff along with its cost. */
-- -----------------------------------------------------------------------------
drop procedure if exists offer_flight;
delimiter //
create procedure offer_flight (in ip_flightID varchar(50), in ip_routeID varchar(50),
    in ip_support_airline varchar(50), in ip_support_tail varchar(50), in ip_progress integer,
    in ip_next_time time, in ip_cost integer)
sp_main: begin

	-- Ensure that the airplane exists idk how
    -- Ensure that the route exists
    -- Ensure that the progress is less than the length of the route
    -- Create the flight with the airplane starting in on the ground
    
    if (select count(*) from route where routeID = ip_routeID) < 1 then leave sp_main; end if; 
    
    if (select count(*) from flight where support_tail = ip_support_tail) >= 1 then leave sp_main; end if;
    
    if ip_cost is null then leave sp_main; end if;
    if ip_next_time is null then leave sp_main; end if;
    
    if (select max(sequence) from route_path group by routeID having routeID = ip_routeID) < ip_progress then leave sp_main; end if;
    
	insert into flight (flightID, routeID, support_airline, support_tail, progress, airplane_status, next_time, cost)
	values (ip_flightID, ip_routeID, ip_support_airline, ip_support_tail, ip_progress, 'on_ground', ip_next_time, ip_cost);


end //
delimiter ;

-- [6] flight_landing()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight landing at the next airport
along it's route.  The time for the flight should be moved one hour into the future
to allow for the flight to be checked, refueled, restocked, etc. for the next leg
of travel.  Also, the pilots of the flight should receive increased experience, and
the passengers should have their frequent flyer miles updated. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_landing;
delimiter //
create procedure flight_landing (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight exists
    -- Ensure that the flight is in the air
    
    -- Increment the pilot's experience by 1
    -- Increment the frequent flyer miles of all passengers on the plane
    -- Update the status of the flight and increment the next time to 1 hour later
		-- Hint: use addtime()
    
    if ip_flightID is null then
		leave sp_main;
	end if;
	
	if (select count(*) from flight where flightID = ip_flightID and airplane_status = 'in_flight') = 0 then
		leave sp_main;
	end if;

	set @r = (select routeID from flight where flightID = ip_flightID);
	set @p = (select progress from flight where flightID = ip_flightID);
	set @a = (select support_airline from flight where flightID = ip_flightID);
	set @t = (select support_tail from flight where flightID = ip_flightID);
	set @l = (select legID from route_path where routeID = @r and sequence = @p);
	set @d = (select distance from leg where legID = @l);
	set @loc = (select locationID from airplane where airlineID = @a and tail_num = @t);

	update flight 
	set airplane_status = 'on_ground', next_time = addtime(next_time, '01:00:00')
	where flightID = ip_flightID;

	update pilot 
	set experience = experience + 1 
	where commanding_flight = ip_flightID;

	update passenger 
	set miles = miles + @d 
	where personID in (
		select personID from person where locationID = @loc
	);

end //
delimiter ;

-- [7] flight_takeoff()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for a flight taking off from its current
airport towards the next airport along it's route.  The time for the next leg of
the flight must be calculated based on the distance and the speed of the airplane.
And we must also ensure that Airbus and general planes have at least one pilot
assigned, while Boeing must have a minimum of two pilots. If the flight cannot take
off because of a pilot shortage, then the flight must be delayed for 30 minutes. */
-- -----------------------------------------------------------------------------
drop procedure if exists flight_takeoff;
delimiter //
create procedure flight_takeoff (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has another leg to fly
    -- Ensure that there are enough pilots (1 for Airbus and general, 2 for Boeing)
		-- If there are not enough, move next time to 30 minutes later
        
	-- Increment the progress and set the status to in flight
    -- Calculate the flight time using the speed of airplane and distance of leg
    -- Update the next time using the flight time
    
	if ip_flightID is null then
		leave sp_main;
	end if;
    
	if (select count(*) from flight where flightID = ip_flightID and airplane_status = 'on_ground') = 0 then
        leave sp_main;
    end if;

    set @r = (select routeID from flight where flightID = ip_flightID);
    set @p = (select progress from flight where flightID = ip_flightID);
    set @sa = (select support_airline from flight where flightID = ip_flightID);
    set @st = (select support_tail from flight where flightID = ip_flightID);
    set @pt = (select plane_type from airplane where airlineID = @sa and tail_num = @st);
    set @pc = (select count(*) from pilot where commanding_flight = ip_flightID);
    
    if ((@pt = 'Boeing' and @pc < 2) or (@pt = 'Airbus' and @pc < 1) or (@pt = 'general' and @pc < 1)) then
        update flight set next_time = addtime(next_time, '00:30:00') 
        where flightID = ip_flightID;
        leave sp_main;
    end if;
    
    set @n = @p + 1;
    
    if (select count(*) from route_path where routeID = @r and sequence = @n) = 0 then
        leave sp_main;
    end if;
    
    set @l = (select legID from route_path where routeID = @r and sequence = @n);
    set @d = (select distance from leg where legID = @l);
    set @s = (select speed from airplane where airlineID = @sa and tail_num = @st);
    set @ft = leg_time(@d, @s);
    
    update flight  
    set airplane_status = 'in_flight',
        progress = @n,
        next_time = addtime(next_time, @ft)
    where flightID = ip_flightID;

    

end //
delimiter ;

-- [8] passengers_board()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting on a flight at
its current airport.  The passengers must be at the same airport as the flight,
and the flight must be heading towards that passenger's desired destination.
Also, each passenger must have enough funds to cover the flight.  Finally, there
must be enough seats to accommodate all boarding passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_board;
delimiter //
create procedure passengers_board (in ip_flightID varchar(50))
sp_main: begin
declare plane_location varchar(50);
    declare seat_cap int;
    declare flight_cost int;
    declare tail_id varchar(50);
    declare route_id varchar(50);
    declare current_leg int;
    declare total_legs int;
    declare prior_leg varchar(50);
    declare boarding_passengers int;
    
    if ip_flightID is null then 
        leave sp_main;
    end if;
    
    if (select count(*) from flight where flightID = ip_flightID) = 0 then
        leave sp_main;
    end if;
    
    if (select airplane_status from flight where flightID = ip_flightID) != 'on_ground' then
        leave sp_main;
    end if;
    
    select a.locationID, a.seat_capacity, f.cost, a.tail_num, f.routeID, f.progress 
    into plane_location, seat_cap, flight_cost, tail_id, route_id, current_leg
    from flight f join airplane a on f.support_tail = a.tail_num 
    where f.flightID = ip_flightID;
    
    select max(sequence) into total_legs from route_path where routeID = route_id;
    
    if current_leg >= total_legs then
        leave sp_main;
    end if;
    
    select a.locationID into prior_leg 
    from flight f join route_path rp on f.routeID = rp.routeID 
    join leg l on rp.legID = l.legID
    join airport a on l.departure = a.airportID 
    where f.flightID = ip_flightID and f.progress = rp.sequence - 1;
    
    select count(*) into boarding_passengers 
    from passenger_vacations v 
    join person p on v.personID = p.personID
    join passenger pa on v.personID = pa.personID 
    where v.sequence = 1
    and p.locationID = prior_leg 
    and pa.funds >= flight_cost
    and v.airportID in (
        select l.arrival 
        from flight f 
        join route_path r on f.routeID = r.routeID 
        join leg l on r.legID = l.legID
        where f.flightID = ip_flightID and f.progress < r.sequence
    );
    
    if boarding_passengers > seat_cap then
        leave sp_main;
    end if;
    
    update passenger pa
    join passenger_vacations v on pa.personID = v.personID
    join person p on v.personID = p.personID
    set pa.funds = pa.funds - flight_cost
    where v.sequence = 1
    and p.locationID = prior_leg 
    and pa.funds >= flight_cost
    and v.airportID in (
        select l.arrival 
        from flight f 
        join route_path r on f.routeID = r.routeID 
        join leg l on r.legID = l.legID
        where f.flightID = ip_flightID and f.progress < r.sequence
    );

    update person p
    join passenger_vacations v on p.personID = v.personID
    join passenger pa on v.personID = pa.personID
    set p.locationID = plane_location
    where v.sequence = 1
    and p.locationID = prior_leg 
    and pa.funds >= flight_cost
    and v.airportID in (
        select l.arrival 
        from flight f 
        join route_path r on f.routeID = r.routeID 
        join leg l on r.legID = l.legID
        where f.flightID = ip_flightID and f.progress < r.sequence
    );
    
    update airplane
    set seat_capacity = seat_capacity - boarding_passengers
    where tail_num = tail_id;

end //
delimiter ;

-- [9] passengers_disembark()
-- -----------------------------------------------------------------------------
/* This stored procedure updates the state for passengers getting off of a flight
at its current airport.  The passengers must be on that flight, and the flight must
be located at the destination airport as referenced by the ticket. */
-- -----------------------------------------------------------------------------
drop procedure if exists passengers_disembark;
delimiter //
create procedure passengers_disembark (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure the flight exists
    -- Ensure that the flight is in the air
    
    -- Determine the list of passengers who are disembarking
	-- Use the following to check:
		-- Passengers must be on the plane supporting the flight
        -- Passenger has reached their immediate next destionation airport
        
	-- Move the appropriate passengers to the airport
    -- Update the vacation plans of the passengers
    if (select count(*) from flight where flightID = ip_flightID and airplane_status = 'on_ground') = 0 then
    leave sp_main;
	end if;

	set @r = (select routeID from flight where flightID = ip_flightID);
	set @p = (select progress from flight where flightID = ip_flightID);
	set @sa = (select support_airline from flight where flightID = ip_flightID);
	set @st = (select support_tail from flight where flightID = ip_flightID);
	set @al = (select locationID from airplane where airlineID = @sa and tail_num = @st);
	set @l = (select legID from route_path where routeID = @r and sequence = @p);
	set @aa = (select arrival from leg where legID = @l);
	set @portl = (select locationID from airport where airportID = @aa);

	create temporary table if not exists disembarking_passengers as
	select p.personID 
	from person p
	join passenger pa on p.personID = pa.personID
	join passenger_vacations pv on p.personID = pv.personID
	where p.locationID = @al
	and pv.airportID = @aa;

	update person
	set locationID = @portl
	where personID in (select personID from disembarking_passengers);

	delete from passenger_vacations
	where personID in (select personID from disembarking_passengers)
	and airportID = @aa;

	drop temporary table if exists disembarking_passengers;


end //
delimiter ;

-- [10] assign_pilot()
-- -----------------------------------------------------------------------------
/* This stored procedure assigns a pilot as part of the flight crew for a given
flight.  The pilot being assigned must have a license for that type of airplane,
and must be at the same location as the flight.  Also, a pilot can only support
one flight (i.e. one airplane) at a time.  The pilot must be assigned to the flight
and have their location updated for the appropriate airplane. */
-- -----------------------------------------------------------------------------
drop procedure if exists assign_pilot;
delimiter //
create procedure assign_pilot (in ip_flightID varchar(50), ip_personID varchar(50))
sp_main: begin

	-- Ensure the flight exists
    -- Ensure that the flight is on the ground
    -- Ensure that the flight has further legs to be flown
    
    -- Ensure that the pilot exists and is not already assigned
	-- Ensure that the pilot has the appropriate license
    -- Ensure the pilot is located at the airport of the plane that is supporting the flight
    
    -- Assign the pilot to the flight and update their location to be on the plane
    
    declare check_license varchar(100);
	declare flight_stat varchar(50);
	declare tail_id varchar(50);
	declare air_type varchar(100);
	declare air_loc varchar(50);
	declare current_route varchar(50);
	declare airline_code varchar(50);
	declare flight_progress int;
	declare latest_seq int;
	declare pilot_flight varchar(50);

	if (select count(flightid) from flight where flightid = ip_flightID) = 0 then
		leave sp_main;
	end if;

	select airplane_status, routeid, progress, support_airline, support_tail
	into flight_stat, current_route, flight_progress, airline_code, tail_id
	from flight
	where flightid = ip_flightID;

	if flight_stat != 'on_ground' then
		leave sp_main;
	end if;

	select max(sequence)
	into latest_seq
	from route_path
	where routeid = current_route;

	if latest_seq is null or flight_progress >= latest_seq then
		leave sp_main;
	end if;
    
    if flight_progress >= latest_seq then
		leave sp_main;
	end if;

	select locationid, plane_type
	into air_loc, air_type
	from airplane
	where airlineid = airline_code and tail_num = tail_id;

	if air_loc is null then
		leave sp_main;
	end if;

	if (select count(personid) from pilot where personid = ip_personID) = 0 then
		leave sp_main;
	end if;

	select commanding_flight
	into pilot_flight
	from pilot
	where personid = ip_personID;

	if pilot_flight is not null then
		leave sp_main;
	end if;

	select license
	into check_license
	from pilot_licenses
	where personid = ip_personID and license = air_type;

	if check_license is null then
		leave sp_main;
	end if;

	update pilot
	set commanding_flight = ip_flightID
	where personid = ip_personID;

	update person
	set locationid = air_loc
	where personid = ip_personID;


end //
delimiter ;

-- [11] recycle_crew()
-- -----------------------------------------------------------------------------
/* This stored procedure releases the assignments for a given flight crew.  The
flight must have ended, and all passengers must have disembarked. */
-- -----------------------------------------------------------------------------
drop procedure if exists recycle_crew;
delimiter //
create procedure recycle_crew (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs
    
    -- Ensure that the flight is empty of passengers
    
    -- Update assignements of all pilots
    -- Move all pilots to the airport the plane of the flight is located at
    
    declare route_id varchar(50);
    declare current_progress int;
    declare max_sequence int;
    declare leg_id varchar(50);
    declare arrival_airport_id varchar(50);
    declare arrival_location_id varchar(50);
    declare plane_location_id varchar(50);
    declare airline_id varchar(50);
    declare tail_number varchar(50);

    if (
        select count(*) from flight where flightID = ip_flightID and airplane_status = 'on_ground'
    ) = 0 then
        leave sp_main;
    end if;

    select routeID, progress, support_airline, support_tail
    into route_id, current_progress, airline_id, tail_number
    from flight
    where flightID = ip_flightID;

    select max(sequence)
    into max_sequence
    from route_path
    where routeID = route_id;

    if current_progress != max_sequence then
        leave sp_main;
    end if;

    select legID
    into leg_id
    from route_path
    where routeID = route_id and sequence = current_progress;

    select arrival
    into arrival_airport_id
    from leg
    where legID = leg_id;

    select locationID
    into arrival_location_id
    from airport
    where airportID = arrival_airport_id;

    select locationID
    into plane_location_id
    from airplane
    where airlineID = airline_id and tail_num = tail_number;

    if exists (
        select 1 from person p
        join passenger pa on p.personID = pa.personID
        where p.locationID = plane_location_id
    ) then
        leave sp_main;
    end if;

    update person
    set locationID = arrival_location_id
    where personID in (
        select personID from pilot where commanding_flight = ip_flightID
    );

    update pilot
    set commanding_flight = null
    where commanding_flight = ip_flightID;

end //
delimiter ;

-- [12] retire_flight()
-- -----------------------------------------------------------------------------
/* This stored procedure removes a flight that has ended from the system.  The
flight must be on the ground, and either be at the start its route, or at the
end of its route.  And the flight must be empty - no pilots or passengers. */
-- -----------------------------------------------------------------------------
drop procedure if exists retire_flight;
delimiter //
create procedure retire_flight (in ip_flightID varchar(50))
sp_main: begin

	-- Ensure that the flight is on the ground
    -- Ensure that the flight does not have any more legs
    
    -- Ensure that there are no more people on the plane supporting the flight
    
    -- Remove the flight from the system
	
	declare status_flight varchar(100);
	declare progress_flight integer;
	declare max_prog integer;
    
	select airplane_status into status_flight from flight where flightID = ip_flightID;
	select progress into progress_flight from flight where flightID = ip_flightID;
	select max(sequence) into max_prog from flight natural join route_path where
	flightID = ip_flightID group by flightID;
    
	if status_flight != 'on_ground' then 
		leave sp_main; 
	end if;
	if progress_flight not in (0, max_prog) then 
		leave sp_main; 
	end if;
    
	delete from flight where flightID = ip_flightID;


end //
delimiter ;

-- [13] simulation_cycle()
-- -----------------------------------------------------------------------------
/* This stored procedure executes the next step in the simulation cycle.  The flight
with the smallest next time in chronological order must be identified and selected.
If multiple flights have the same time, then flights that are landing should be
preferred over flights that are taking off.  Similarly, flights with the lowest
identifier in alphabetical order should also be preferred.

If an airplane is in flight and waiting to land, then the flight should be allowed
to land, passengers allowed to disembark, and the time advanced by one hour until
the next takeoff to allow for preparations.

If an airplane is on the ground and waiting to takeoff, then the passengers should
be allowed to board, and the time should be advanced to represent when the airplane
will land at its next location based on the leg distance and airplane speed.

If an airplane is on the ground and has reached the end of its route, then the
flight crew should be recycled to allow rest, and the flight itself should be
retired from the system. */
-- -----------------------------------------------------------------------------
drop procedure if exists simulation_cycle;
delimiter //
create procedure simulation_cycle ()
sp_main: begin
declare flight_to_process varchar(50);
    declare state_of_flight varchar(20);
    declare num_legs int;
    declare current_leg int;
    declare route_id varchar(50);
    
    -- Identify the next flight to be processed
    -- Order by: next_time (earliest first)
    -- If tie: landing (in_flight) before taking off (on_ground)
    -- If still tie: alphabetically by flightID
    select flightID
    into flight_to_process
    from flight
    where next_time is not null
    order by next_time asc, 
             case airplane_status when 'in_flight' then 0 else 1 end, 
             flightID asc
    limit 1;
    
    -- Exit if no flights to process
    if flight_to_process is null then
        leave sp_main;
    end if;
    
    -- Get current flight status and details
    select airplane_status, routeID, progress
    into state_of_flight, route_id, current_leg
    from flight
    where flightID = flight_to_process;
    
    -- Get total number of legs in the route
    select max(sequence)
    into num_legs
    from route_path
    where routeID = route_id;
    
    -- Process flight based on its current state
    if state_of_flight = 'in_flight' then
        -- Land the flight
        call flight_landing(flight_to_process);
        
        -- Allow passengers to disembark
        call passengers_disembark(flight_to_process);
        
        -- Re-fetch the progress after landing since it changed
        select progress
        into current_leg
        from flight
        where flightID = flight_to_process;
        
        -- Check if flight has reached the end of its route
        if current_leg >= num_legs then
            -- Recycle the crew for rest
            call recycle_crew(flight_to_process);
            
            -- Retire the flight from the system
            call retire_flight(flight_to_process);
        end if;
    else -- flight is on_ground
        -- Board passengers for the next leg
        call passengers_board(flight_to_process);
        
        -- Takeoff for next destination
        call flight_takeoff(flight_to_process);
    end if;
end //
delimiter ;


end //
delimiter ;

-- [14] flights_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where flights that are currently airborne are located. 
We need to display what airports these flights are departing from, what airports 
they are arriving at, the number of flights that are flying between the 
departure and arrival airport, the list of those flights (ordered by their 
flight IDs), the earliest and latest arrival times for the destinations and the 
list of planes (by their respective flight IDs) flying these flights. */
-- -----------------------------------------------------------------------------
create or replace view flights_in_the_air (departing_from, arriving_at, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as
-- select '_', '_', '_', '_', '_', '_', '_';
select l.departure, l.arrival, count(f.flightID), group_concat(f.flightID separator ','), min(f.next_time),
max(f.next_time), group_concat(a.locationID separator ',')
from flight f 
join route_path r on f.routeID = r.routeID and r.sequence = f.progress
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num 
join leg l on r.legID = l.legID
where f.airplane_status = 'in_flight'
group by l.legID;


-- [15] flights_on_the_ground()
-- ------------------------------------------------------------------------------
/* This view describes where flights that are currently on the ground are 
located. We need to display what airports these flights are departing from, how 
many flights are departing from each airport, the list of flights departing from 
each airport (ordered by their flight IDs), the earliest and latest arrival time 
amongst all of these flights at each airport, and the list of planes (by their 
respective flight IDs) that are departing from each airport.*/
-- ------------------------------------------------------------------------------
create or replace view flights_on_the_ground (departing_from, num_flights,
	flight_list, earliest_arrival, latest_arrival, airplane_list) as 
-- select '_', '_', '_', '_', '_', '_';
select l.departure, count(f.flightID), group_concat(f.flightID separator ','), min(f.next_time), 
max(f.next_time), group_concat(a.locationID separator ',')
from flight f
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join route_path rp on f.routeID = rp.routeID and f.progress + 1 = rp.sequence
join leg l on rp.legID = l.legID
where f.airplane_status = 'on_ground'
group by l.departure
union
select l.arrival, count(f.flightID), group_concat(f.flightID separator ','), min(f.next_time), 
max(f.next_time), group_concat(a.locationID separator ',')
from flight f
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join leg l on r.legID = l.legID
where f.airplane_status = 'on_ground'
and r.sequence = (
    select max(sequence) from route_path where routeID = f.routeID
)
group by l.arrival;



-- [16] people_in_the_air()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently airborne are located. We 
need to display what airports these people are departing from, what airports 
they are arriving at, the list of planes (by the location id) flying these 
people, the list of flights these people are on (by flight ID), the earliest 
and latest arrival times of these people, the number of these people that are 
pilots, the number of these people that are passengers, the total number of 
people on the airplane, and the list of these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_in_the_air (departing_from, arriving_at, num_airplanes,
	airplane_list, flight_list, earliest_arrival, latest_arrival, num_pilots,
	num_passengers, joint_pilots_passengers, person_list) as
-- select '_', '_', '_', '_', '_', '_', '_', '_', '_', '_', '_'; 
select l.departure, l.arrival, count(distinct f.flightID), group_concat(distinct a.locationID separator ','), 
group_concat(distinct f.flightID separator ','), min(f.next_time), max(f.next_time), count(p2.personID),
count(p3.personID), count(p.personID), group_concat(distinct p.personID separator ',')
from flight f
join route_path r on f.routeID = r.routeID and f.progress = r.sequence
join airplane a on f.support_airline = a.airlineID and f.support_tail = a.tail_num
join leg l on r.legID = l.legID
join person p on p.locationID = a.locationID
left join pilot p2 on p.personID = p2.personID and p2.commanding_flight = f.flightID
left join passenger p3 on p.personID = p3.personID
where f.airplane_status = 'in_flight'
group by l.departure, l.arrival;


-- [17] people_on_the_ground()
-- -----------------------------------------------------------------------------
/* This view describes where people who are currently on the ground and in an 
airport are located. We need to display what airports these people are departing 
from by airport id, location id, and airport name, the city and state of these 
airports, the number of these people that are pilots, the number of these people 
that are passengers, the total number people at the airport, and the list of 
these people by their person id. */
-- -----------------------------------------------------------------------------
create or replace view people_on_the_ground (departing_from, airport, airport_name,
	city, state, country, num_pilots, num_passengers, joint_pilots_passengers, person_list) as
-- select '_', '_', '_', '_', '_', '_', '_', '_', '_', '_';
select a.airportID, a.locationID, a.airport_name, a.city, a.state, a.country, count(p2.personID), count(p3.personID),
count(p.personID), group_concat(p.personID separator ',')
from airport a
join person p on a.locationID = p.locationID
left join pilot p2 on p.personID = p2.personID 
left join passenger p3 on p.personID = p3.personID
group by
a.airportID, a.locationID, a.airport_name, a.city, a.state;



-- [18] route_summary()
-- -----------------------------------------------------------------------------
/* This view will give a summary of every route. This will include the routeID, 
the number of legs per route, the legs of the route in sequence, the total 
distance of the route, the number of flights on this route, the flightIDs of 
those flights by flight ID, and the sequence of airports visited by the route. */
-- -----------------------------------------------------------------------------
create or replace view route_summary (route, num_legs, leg_sequence, route_length,
	num_flights, flight_list, airport_sequence) as
-- select '_', '_', '_', '_', '_', '_', '_';
select r.routeID, count(l.legID), group_concat(l.legID separator ','), sum(l.distance),
(select count(flightID) from flight where routeID = r.routeID),
(select group_concat(flightID separator ',') from flight where routeID = r.routeID),
group_concat(concat(l.departure, '->', l.arrival) separator ',')
from route_path r
join leg l on r.legID = l.legID
group by
r.routeID;


-- [19] alternative_airports()
-- -----------------------------------------------------------------------------
/* This view displays airports that share the same city and state. It should 
specify the city, state, the number of airports shared, and the lists of the 
airport codes and airport names that are shared both by airport ID. */
-- -----------------------------------------------------------------------------
create or replace view alternative_airports (city, state, country, num_airports,
	airport_code_list, airport_name_list) as
-- select '_', '_', '_', '_', '_', '_';
select a.city, a.state, a.country, count(*), group_concat(a.airportID separator ','), group_concat(airport_name separator ',')
from airport a
group by a.city, a.state, a.country having count(*) > 1;

