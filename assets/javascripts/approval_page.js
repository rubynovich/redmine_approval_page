function approve_item(elem,url,id){
    new Ajax.Request(url,
        {
            method:'put',
            onSuccess: function(transport){
                var response = transport.responseText || "no response text";
                eval(response)
            },
            onFailure: function(){ alert('Something went wrong...') }
        });

    var checkbox = $(elem)
    if (checkbox)
        if (checkbox.checked)
          checkbox.up().addClassName('is-done-approval-item');
        else
          checkbox.up().removeClassName('is-done-approval-item');
}
