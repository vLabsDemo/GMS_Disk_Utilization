GetDiskDetails: function(type, domainSysId, description, source) {
    if (domainSysId == '6c2984acdb5f24d0848daa4dd3961952') //EXPO
    {

        var desc = description;
        var src = source;
        if((src == 'Nagios') && type.includes("Disk Usage on"))
        {
            var drivename = type.match(/Disk\sUsage\son\s(\w\:)/);
        }
        else
        {
            var drivename = desc.match(/Disk Space Alert.*\-(\w\:).*/);
        }
        if (drivename != null) {
            try {
                var drv = drivename[1].trim();
                result = {
                    "result": "Success",
                    "DriveName": drv
                };
            } catch (e) {
                result = {
                    "result": "Failure"
                };
            }

        } else {
            result = {
                "result": "Failure"
            };
        }
    }
     else {
        result = {
            "result": "Failure"
        };
    }
    return result;
},