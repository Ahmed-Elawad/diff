public interface UserDAInterface {
    List<User> getAllActiveUsersByNameSearch(String searchName);
    List<User> getAllActiveUsers();
}