class Dashing.SensuTable extends Dashing.Widget

   ready: ->
    # This is fired when the widget is done being rendered
    console.log('i am at ready')

   onData: (data) ->
     console.log('reading table data')
     # Identify team from query string
     # eg. http://dashing.domain.org/sensu?team=devops
     search_query = window.location.search.substring(1)
     console.log('search query', search_query)
     [key, team] = search_query.split("=")
     console.log "you are part of " + team

     # store team as a root function so can be accessed globablly
     root = exports ? this
     root.team = -> team

     # init vars
     count = {'critical': 0, 'warning': 0, 'unknown': 0}
     filtered_array = []

     if @team() == 'all' or @team() == ''  # all teams
       # don't do any filtering and just proceed
       # with all collected values
       # copy from tmp variables
       Dashing.widgets[@id][0]['rows'] = data['rows_tmp']

       # set critical/warning/unknown count vars in DOM
       Dashing.widgets['sensu-status'][0]['criticals'] =
         Dashing.widgets['sensu-status'][0]['criticals_tmp']
       Dashing.widgets['sensu-status'][0]['warnings'] =
         Dashing.widgets['sensu-status'][0]['warnings_tmp']
       Dashing.widgets['sensu-status'][0]['unknowns'] =
         Dashing.widgets['sensu-status'][0]['unknowns_tmp']
     else
       # team selected, do filtering
       for row, index in data['rows_tmp']  # index is row number
         # get urgency of current row
         urgency = data['rows_tmp'][index]['cols'][3]['class']

         if data['rows_tmp'][index]['cols'][3]['value'] == @team()
           console.log('correct team:', @team())
           count[urgency] += 1  # increment count of urgency
           filtered_array.push(row)  # push row to filtered array

       # set DOM with all data from filters
       Dashing.widgets[@id][0]['rows'] = filtered_array
       Dashing.widgets['sensu-status'][0]['criticals'] = count['critical']
       Dashing.widgets['sensu-status'][0]['warnings'] = count['warning']
       Dashing.widgets['sensu-status'][0]['unknowns'] = count['unknown']

     # set header row of table
     Dashing.widgets[@id][0]['hrows'] = data['hrows_tmp']
     Dashing.widgets[@id].push(@)

     # clean-up old data
     Dashing.widgets['sensu-status'][0]['unknowns_tmp'] =''
     Dashing.widgets['sensu-status'][0]['criticals_tmp'] =''
     Dashing.widgets['sensu-status'][0]['warnings_tmp'] =''
     Dashing.widgets[@id][0]['rows_tmp'] = ''
     # need the following line  as CS will return last line in a given scope
     # when rendered to JS which may cause a fork bomb and
     # eventually kill the browser (and perhaps the whole machine)
     return
