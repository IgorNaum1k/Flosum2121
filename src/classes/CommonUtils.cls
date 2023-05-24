public with sharing class CommonUtils {
    public static String getNameSpacePrefix() {
        String nameSpacePrefix = CommonUtils.class.getName().substringBefore('CommonUtils');
        if (nameSpacePrefix != '') {
            return nameSpacePrefix = nameSpacePrefix.replace('.', '');
        }
        return '';
    }
}