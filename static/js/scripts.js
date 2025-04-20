document.addEventListener('DOMContentLoaded', function() {
    // Handle airline selection for airplane-related forms
    const airlineSelect = document.getElementById('airline_id');
    const tailSelect = document.getElementById('support_tail');
    
    if (airlineSelect && tailSelect) {
        airlineSelect.addEventListener('change', function() {
            const airlineId = this.value;
            
            // Clear current options
            tailSelect.innerHTML = '<option value="">Select Tail Number</option>';
            
            if (airlineId) {
                // Fetch tail numbers for the selected airline
                fetch(`/api/get_tails_for_airline/${airlineId}`)
                    .then(response => response.json())
                    .then(data => {
                        data.forEach(item => {
                            const option = document.createElement('option');
                            option.value = item.tail_num;
                            option.textContent = item.tail_num;
                            tailSelect.appendChild(option);
                        });
                    })
                    .catch(error => {
                        console.error('Error fetching tail numbers:', error);
                    });
            }
        });
    }
    
    // Toggle fields based on plane type
    const planeTypeSelect = document.getElementById('plane_type');
    const boeingFields = document.querySelector('.boeing-fields');
    const airbusFields = document.querySelector('.airbus-fields');
    
    if (planeTypeSelect && (boeingFields || airbusFields)) {
        planeTypeSelect.addEventListener('change', function() {
            const planeType = this.value.toLowerCase();
            
            if (boeingFields) {
                boeingFields.style.display = planeType === 'boeing' ? 'block' : 'none';
            }
            
            if (airbusFields) {
                airbusFields.style.display = planeType === 'airbus' ? 'block' : 'none';
            }
        });
    }
    
    // Toggle fields based on person type
    const taxIdField = document.getElementById('tax_id');
    const experienceField = document.getElementById('experience');
    const milesField = document.getElementById('miles');
    const fundsField = document.getElementById('funds');
    const personTypeRadios = document.querySelectorAll('input[name="person_type"]');
    
    if (personTypeRadios.length > 0 && taxIdField && experienceField && milesField && fundsField) {
        personTypeRadios.forEach(radio => {
            radio.addEventListener('change', function() {
                if (this.value === 'pilot') {
                    taxIdField.parentElement.style.display = 'block';
                    experienceField.parentElement.style.display = 'block';
                    milesField.parentElement.style.display = 'none';
                    fundsField.parentElement.style.display = 'none';
                    
                    taxIdField.required = true;
                    experienceField.required = true;
                    milesField.required = false;
                    fundsField.required = false;
                    
                    milesField.value = '';
                    fundsField.value = '';
                } else {
                    taxIdField.parentElement.style.display = 'none';
                    experienceField.parentElement.style.display = 'none';
                    milesField.parentElement.style.display = 'block';
                    fundsField.parentElement.style.display = 'block';
                    
                    taxIdField.required = false;
                    experienceField.required = false;
                    milesField.required = true;
                    fundsField.required = true;
                    
                    taxIdField.value = '';
                    experienceField.value = '';
                }
            });
        });
    }
    
    // DataTable initialization for all tables
    const tables = document.querySelectorAll('.data-table');
    if (tables.length > 0) {
        tables.forEach(table => {
            $(table).DataTable({
                responsive: true,
                pageLength: 10,
                lengthMenu: [5, 10, 25, 50, 100],
                dom: 'Bfrtip',
                buttons: [
                    'copy', 'csv', 'excel', 'pdf', 'print'
                ]
            });
        });
    }
    
    // Auto-dismiss alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert');
    if (alerts.length > 0) {
        setTimeout(() => {
            alerts.forEach(alert => {
                alert.style.opacity = '0';
                setTimeout(() => {
                    alert.style.display = 'none';
                }, 500);
            });
        }, 5000);
    }
});
