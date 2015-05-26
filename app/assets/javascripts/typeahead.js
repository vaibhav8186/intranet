var movies = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
        url: '/users?query=%QUERY',
        filter: function (users) {
            return $.map(users, function (user) {
                return {
                    email: user.email ,id: user._id
                };
            });
        }
    }
});
// initialize the bloodhound suggestion engine

movies.initialize();
$(document).on('nested:fieldAdded', function(event){
  $('.typeahead').typeahead(null, {
    displayKey: function(user) {
           return user.email;
        },
    source: movies.ttAdapter()
}); 
});
$(document).on('nested:fieldAdded', function(event){
$('.typeahead').on('typeahead:selected', function(event, datum) {
console.log($(this).parent().parent().parent().find('input.hid').val(datum._id));//.val(datum.id);
});
});
