public with sharing class LeadEmailQueueable implements Queueable {
    private Set<Id> leadIds;
    private Integer mAXRETRYCOUNT = 3;
    private Integer retryCount = 0;
    public LeadEmailQueueable(Set<Id> leadIds) {
        this.leadIds = leadIds;
    }

    private LeadEmailQueueable(Set<Id> leadIds , Integer retryCount) {
        this.leadIds = leadIds;
        this.retryCount = retryCount;
    }

    public void execute(QueueableContext context) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        
            List<Lead> leads = [SELECT Id, Email, FirstName, LastName FROM Lead WHERE Id IN :leadIds AND Email != null];
            for (Lead lead : leads) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new String[] { lead.Email });
                email.setSubject('Important Update');
                email.setPlainTextBody('Dear ' + lead.FirstName + ' ' + lead.LastName + ',\n\nThis is an important update regarding your inquiry.\n\nBest regards,\nYour Company');
                emails.add(email);
            }
            try {
            if (!emails.isEmpty()) {
                Messaging.sendEmail(emails);
            }
        } catch (Exception e) {
            if (retryCount < mAXRETRYCOUNT) {
                System.enqueueJob(new LeadEmailQueueable(leadIds, retryCount + 1));
            } else {
                // Log the failure after max retries
                System.debug('Failed to send emails after ' + mAXRETRYCOUNT + ' attempts. Error: ' + e.getMessage());
            }
        }
    }
}