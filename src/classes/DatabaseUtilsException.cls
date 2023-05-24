public with sharing class DatabaseUtilsException extends Exception {
    public enum ExceptionType {
        GENERIC,
        OBJECT_ACCESS_VIOLATION,
        FIELD_ACCESS_VIOLATION,
        SHARING_ACCESS_VIOLATION,
        NO_RECORD_FOUND,
        FIELD_NOT_FOUND
    }

    public enum ExceptionReason {
        GENERIC,
        NO_CREATE,
        NO_READ,
        NO_UPDATE,
        NO_DELETE
    }

    private ExceptionType eType;
    private ExceptionReason eReason;
    private String eObject;
    private String eField;
    private String eText;

    public DatabaseUtilsException(
        String eText,
        ExceptionType eType,
        ExceptionReason eReason,
        String eObject,
        String eField
    ) {
        this.eText = eText;
        this.eType = eType;
        this.eReason = eReason;
        this.eObject = eObject;
        this.eField = eField;
    }

    public ExceptionType getExceptionType() {
        return this.eType;
    }

    public ExceptionReason getExceptionReason() {
        return this.eReason;
    }

    public String getExceptionObject() {
        return this.eObject;
    }

    public String getExceptionField() {
        return this.eField;
    }

    public String getText() {
        return this.eText;
    }

    public override String getMessage() {
        return this.eText;
    }
}