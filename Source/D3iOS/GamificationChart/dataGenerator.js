var DATAG_MOD = (function(){
  return {
    newDataSet : function(username) {
      dataSet = [];
                 var file_path= location.pathname;
                 var username_start = file_path.search("username=");
                 var username= file_path.slice(username_start+9) ;
                 $(".username").html(username)
                 
                 var Name = username;
      $.ajax({
        url: "https://badges.appliedx.amat.com/api/v0/chart?username=" + Name,
        type: 'GET',
        async: false,
        cache: false,
        timeout: 30000,
        success: function(data){ 
             var labelSet = Object.keys(data);
             $.each(data, function(key, value) { 
            console.log(key);
            console.log(value);
            var entry = { "label" : key, "value" : value[1]};
            dataSet.push(entry);
            }); 
         console.log(JSON.stringify(dataSet));
        }
      });
     $.ajax({
            url: "https://badges.appliedx.amat.com/api/v0/points?username=" + Name,
            type: 'GET',
            async: false,
            cache: false,
            timeout: 30000,
            success: function(data){
            document.getElementById("pointScore").innerHTML = data.points
            //console.log(JSON.stringify(dataSet));
            }
            });
      $.ajax({
        url: "https://badges.appliedx.amat.com/api/v0/badges?username=" + Name,
        type: 'GET',
        async: false,
        cache: false,
        timeout: 30000,
        success: function(data){   
             var badge = [];
             var badges_urls = [];
             var badges_title = [];
             var badges_points = [];
             for (var i = 0; i < data.length; i++) {
            var badge_img_url = data[i].url;
            var badge_title = data[i].title;
            var status_points = data[i].status_points;
            badges_urls.push(badge_img_url);
            badges_title.push(badge_title);
            badges_points.push(status_points);
          } 
          var html = "<table><tr>";
          for (var i = 0; i < data.length; i++) {
          var badge_html = "<td>" +"<img src='" +  badges_urls[i] + "' width=100 height=100>" + "</td>";
          html = html + badge_html;
          }
          html = html + "</tr><tr>";
             

        $(".badges").html(html);
      }
      });
      return dataSet;
    }
  };
});
