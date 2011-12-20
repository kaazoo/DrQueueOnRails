// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .


$('form[data-remote]')
$('a[data-remote],input[data-remote]')

$('.mybutton').bind('ajax:beforeSend', function(){
  alert("beforeSend!");
  return false;
});

$('.mybutton').bind('ajax:success', function(){
  alert("success!");
  return false;
});

$(function () {
  $('.mybutton').bind('ajax:beforeSend', function (evt, xhr, settings) {
    alert("beforeSend!");
    return false;
  })
  $('.mybutton').click(function () {
    nums = document.getElementById("rendersession_num_slaves").value
    rtime = document.getElementById("rendersession_run_time").value
    vtype = document.getElementById("rendersession_vm_type").value
    cdiv = document.getElementById("costs")

    jQuery.post("/rendersessions/calculate_costs", { num_slaves: nums, run_time: rtime, vm_type: vtype }, function(data) {
      $('#costs').html(data);
    });

    return false;
    })
});

