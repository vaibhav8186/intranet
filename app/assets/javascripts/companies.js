$(document).ready(function(){
  $("#company-submit").click(function(){
    // $(".fields:hidden").remove();
    var emails =get_emails();
    var emails_arr = emails.sort();
    for (var i = 0; i < emails.length - 1; i++) {
      if (emails_arr[i + 1] == emails[i]) {
        $("#nested-error").html("Email must be unique : " + emails[i]);
        return false;
      }
    }
  });
});

function get_emails(){
  var emails = [];
  $("input.email.required.string").each(function(index, email_div) {
    emails.push(email_div.value);
  });
  return emails
}