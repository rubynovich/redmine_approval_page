function approve_item(elem,url,id){
    $.ajax({url: url,
        dataType: 'script',
        data: 'approval_item_' + id})
    var checkbox = $(elem)
    if (checkbox.is(':checked'))
        checkbox.removeAttr('checked')
    else
        checkbox.attr('checked', true)

}
