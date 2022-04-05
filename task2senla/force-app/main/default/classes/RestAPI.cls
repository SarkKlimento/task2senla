@RestResource(urlMapping='/Leads')
global class LeadRestApi {
    @HttpPost
    global static Id getLeadByIdOrEmail(){
    
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        Lead getLead = LeadRESTHelper(req, res);// Очень плохой нейминг, да и смысла в этом вынесении нет
        return getLead.Id; // А если ничего не нашли? А если ошибка?
    }

    @HttpPut
    global static Id createTaskForLead(){

        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;                         

        Lead targetLead = LeadRESTHelper(req,res);//Нет смысла переиспользывать весь метод когда нужно только часть его (стоит разделить)
        
        List<String> validSubjects = new List<String>();
        validSubjects.add('Call'); // Почему именно этот?
        Map<String, Object> subjectParameter = 
        (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

        String subj = subjectParameter.get('task body').tostring();// А если пусто?
		Task newTask;
        
        if (targetLead!=null) {
            if (validSubjects.contains(subj)) {
                newTask = new Task(Subject = 'Other' ,
                                Status = 'Not Started',
                                WhoID = targetLead.Id, 
                                OwnerId = targetLead.OwnerId);
            }
            else {
                newTask = new Task(Status = 'Not Started',
                                WhoID = targetLead.Id, 
                                OwnerId = targetLead.OwnerId);
            }
            insert newTask;
            System.debug(LoggingLevel.FINEST,newTask);// Бесполезно
            return newTask.Id;// Зачем?
        }
        else {
            System.debug(LoggingLevel.ERROR,'Cannot create Task!');
            return null;// А ошибку кинуть?
        }
    }

    public  static Lead LeadRESTHelper(RestRequest req, RestResponse res) {// Переменные контекста можно получить в любой функции контекста, нет смысла в таких параметрах
        Lead returnLead;
        try{//Форматирование почти везде плохое, больше про него не пишу
            String findLead = req.requestBody.tostring();//Плохой нейминг
            
            Map<String, Object> parMap = (Map<String, Object>) JSON.deserializeUntyped(findLead);
            String leadId = parMap.get('id').toString();
            String leadEmail = parMap.get('email').toString();
            if(leadId != null && leadId.length() == 18){// А если есть и то и то?
                returnLead = [SELECT Id, Name, OwnerId // Разве нам этой информации хватит?
                        FROM Lead
                        WHERE Id = :leadId
                        LIMIT 1];
            }
            else if(leadEmail != null && leadEmail.contains('@')){
                returnLead = [SELECT Id, Name, OwnerId//Same
                        FROM Lead
                        WHERE Email = :leadEmail
                        LIMIT 1];
            }
            else {
                System.debug(LoggingLevel.ERROR,'Cannot find the Lead!'); // Весь текст либо константы либо Custom Labels
                //res.statusCode = 400;
                return null; // А ошибку кинуть? 
                //returnLead =  null;
            }
            
            System.debug(LoggingLevel.INFO,returnLead); // бесполезно
            //res.statusCode = 200;
            res.responseBody = Blob.valueOf(JSON.serialize(returnLead));
            return returnLead;
        }catch(NullPointerException e){
            e.getStackTraceString();
            System.debug(LoggingLevel.INFO,'Null pointer exception!!!');
            return null;
        }
    }
}
