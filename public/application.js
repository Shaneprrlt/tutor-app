(function() {

  // handles searching for new tutors
  $("#find-tutors-button").on('click', function(evt) {

    // do not submit the form
    evt.preventDefault();

    // clear the old search results
    $("#search-results").html(null);

    // get the value of the search query
    var tutor_query = $("#find-tutors-input").val();

    if(tutor_query.length > 0) {
      $.get('/tutors/search', { query: tutor_query }, function(data) {

        $.each(data, function(index, tutor) {

          $("#search-results").append(
            $("<li>").prop({
              class: "search-results-item",
              id: tutor.id
            }).html(tutor.name)
          );
        });

      });
    }
  });

  // handles adding a new tutor from the search results
  $(document).on('click', '.search-results-item', function() {
    // get the tutor id from the id property
    var tutor_id = $(this).prop('id');
    // send a request to add tutor
    $.post('/tutors/add', { tutor_id: tutor_id }, function(req, res) {

      location.reload();
    });
  });

  // handles canceling an appointment
  $(document).on('click', '.cancel-appt-button', function() {

    // get the appt id from the id property
    var appt_id = $(this).prop('id');

    // send a request to cancel the appointment
    $.post('/appointments/cancel', { appt_id : appt_id }, function(req, res) {
      location.reload();
    });
  });

  // handles marking an appointment as being attended
  $(".mark-attended").on('change', function() {
    if(this.checked)
    {
        // get the appointment id
        var appt_id = $(this).prop('id');
        var checkbox = this;

        // send a request to mark the appointment as attended
        $.post('/appointments/attend', { appt_id : appt_id }, function(req, res) {

          // make this row gray so it is clear that this
          // appointment has been marked attended
          $(checkbox).closest('tr').prop('class', 'active');

        });
    }
  });

} ());
