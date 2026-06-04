public class RenewalLogHelper {

    public static void writeToLog(RenewalLogHelper.LogType logType, String message, String contractId){
        try {
            Renewal_Log__c renewalLog = new Renewal_Log__c();

            //default to info
            renewalLog.Message_Type__c = 'Info';
            if (logType != null && logType == RenewalLogHelper.LogType.ERROR){
                renewalLog.Message_Type__c = 'Error';
            }
            renewalLog.Log_Message__c = message;
            if (contractId != null){
                renewalLog.Contract__c = contractId;
            }
            insert renewalLog;
    
        } catch (Exception e){
            System.debug(e);
        }


    }

    public enum LogType {ERROR,INFO}


}