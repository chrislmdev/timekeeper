public with sharing class TimeEntryRateService {
    public static void applyDefaultsAndRates(List<Time_Entry__c> newRows, Map<Id, Time_Entry__c> oldMap) {
        Boolean isInsert = oldMap == null;

        Set<Id> projectIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        for (Time_Entry__c te : newRows) {
            if (te.Project__c != null) {
                projectIds.add(te.Project__c);
            }
            if (te.OwnerId != null) {
                ownerIds.add(te.OwnerId);
            }
        }

        Map<Id, Project__c> projectsById = loadProjects(projectIds);
        Map<Id, User> ownersById = loadOwners(ownerIds);

        if (isInsert) {
            applyOwnerDefaults(newRows, ownersById);
        }

        projectIds.clear();
        for (Time_Entry__c te : newRows) {
            if (te.Project__c != null) {
                projectIds.add(te.Project__c);
            }
        }
        projectsById = loadProjects(projectIds);

        Set<String> offerings = new Set<String>();
        Set<String> roles = new Set<String>();
        Set<String> pools = new Set<String>();
        Date minDate;
        Date maxDate;

        for (Time_Entry__c te : newRows) {
            Time_Entry__c old = oldMap == null ? null : oldMap.get(te.Id);
            if (!needsRateRecalc(te, old)) {
                continue;
            }
            Project__c p = projectsById.get(te.Project__c);
            if (p == null || String.isBlank(p.Offering__c)) {
                continue;
            }
            if (String.isBlank(te.Job_Role__c) || String.isBlank(te.Labor_Pool__c) || te.Work_Date__c == null) {
                continue;
            }
            offerings.add(p.Offering__c);
            roles.add(te.Job_Role__c);
            pools.add(te.Labor_Pool__c);
            minDate = minDate == null ? te.Work_Date__c : minOf(minDate, te.Work_Date__c);
            maxDate = maxDate == null ? te.Work_Date__c : maxOf(maxDate, te.Work_Date__c);
        }

        Map<String, List<Rate_Card__c>> cardsByKey = new Map<String, List<Rate_Card__c>>();
        if (!offerings.isEmpty() && minDate != null && maxDate != null) {
            for (Rate_Card__c rc : [
                SELECT Id, Offering__c, Job_Role__c, Labor_Pool__c, Effective_Start__c, Effective_End__c, Hourly_Rate__c
                FROM Rate_Card__c
                WHERE
                    Offering__c IN :offerings
                    AND Job_Role__c IN :roles
                    AND Labor_Pool__c IN :pools
                    AND Effective_Start__c <= :maxDate
                    AND (Effective_End__c = NULL OR Effective_End__c >= :minDate)
            ]) {
                String key = keyFor(rc.Offering__c, rc.Job_Role__c, rc.Labor_Pool__c);
                if (!cardsByKey.containsKey(key)) {
                    cardsByKey.put(key, new List<Rate_Card__c>());
                }
                cardsByKey.get(key).add(rc);
            }
        }

        for (Time_Entry__c te : newRows) {
            Time_Entry__c old = oldMap == null ? null : oldMap.get(te.Id);
            if (!needsRateRecalc(te, old)) {
                continue;
            }
            Project__c p = projectsById.get(te.Project__c);
            if (p == null
                || String.isBlank(p.Offering__c)
                || te.Work_Date__c == null
                || String.isBlank(te.Job_Role__c)
                || String.isBlank(te.Labor_Pool__c)) {
                te.Rate_Applied__c = null;
                continue;
            }
            String key = keyFor(p.Offering__c, te.Job_Role__c, te.Labor_Pool__c);
            Rate_Card__c best = pickCard(cardsByKey.get(key), te.Work_Date__c);
            te.Rate_Applied__c = best == null ? null : best.Hourly_Rate__c;
        }
    }

    private static Map<Id, Project__c> loadProjects(Set<Id> projectIds) {
        if (projectIds.isEmpty()) {
            return new Map<Id, Project__c>();
        }
        return new Map<Id, Project__c>([SELECT Id, Offering__c FROM Project__c WHERE Id IN :projectIds]);
    }

    private static Map<Id, User> loadOwners(Set<Id> ownerIds) {
        if (ownerIds.isEmpty()) {
            return new Map<Id, User>();
        }
        return new Map<Id, User>([
            SELECT Id, CD_Default_Job_Role__c, CD_Default_Labor_Pool__c
            FROM User
            WHERE Id IN :ownerIds
        ]);
    }

    private static void applyOwnerDefaults(List<Time_Entry__c> newRows, Map<Id, User> ownersById) {
        for (Time_Entry__c te : newRows) {
            User u = ownersById.get(te.OwnerId);
            if (u == null) {
                continue;
            }
            if (String.isBlank(te.Job_Role__c) && String.isNotBlank(u.CD_Default_Job_Role__c)) {
                te.Job_Role__c = u.CD_Default_Job_Role__c;
            }
            if (String.isBlank(te.Labor_Pool__c) && String.isNotBlank(u.CD_Default_Labor_Pool__c)) {
                te.Labor_Pool__c = u.CD_Default_Labor_Pool__c;
            }
        }
    }

    private static Boolean needsRateRecalc(Time_Entry__c neu, Time_Entry__c old) {
        if (old == null) {
            return true;
        }
        return neu.Project__c != old.Project__c
            || neu.Work_Date__c != old.Work_Date__c
            || neu.Job_Role__c != old.Job_Role__c
            || neu.Labor_Pool__c != old.Labor_Pool__c;
    }

    private static String keyFor(String offering, String jobRole, String laborPool) {
        return offering + '|' + jobRole + '|' + laborPool;
    }

    private static Rate_Card__c pickCard(List<Rate_Card__c> cards, Date workDate) {
        if (cards == null || cards.isEmpty() || workDate == null) {
            return null;
        }
        Rate_Card__c best = null;
        for (Rate_Card__c rc : cards) {
            if (rc.Effective_Start__c > workDate) {
                continue;
            }
            if (rc.Effective_End__c != null && rc.Effective_End__c < workDate) {
                continue;
            }
            if (best == null || rc.Effective_Start__c > best.Effective_Start__c) {
                best = rc;
            }
        }
        return best;
    }

    private static Date minOf(Date a, Date b) {
        return a < b ? a : b;
    }

    private static Date maxOf(Date a, Date b) {
        return a > b ? a : b;
    }
}
