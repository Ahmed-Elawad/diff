trigger CampaignMemberBefore on CampaignMember (before insert,before update) {
    if(trigger.isinsert) DG_UTMController.UpdateCMs(trigger.new);
}