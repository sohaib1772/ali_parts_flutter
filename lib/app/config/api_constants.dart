class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.maktabali.com';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzg0MzI3MzE3LCJleHAiOjE5NDIwMDczMTd9.fzSYf83cI68kEj8LYz20cBwsYVUI9M5gqD7mgeTpDcA';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 20);

  // Endpoints
  static const String products = '/rest/v1/products';
  static const String categories = '/rest/v1/categories';
  static const String brands = '/rest/v1/brands';
  static const String carModels = '/rest/v1/car_models';
  static const String banners = '/rest/v1/banners';
  static const String cartItems = '/rest/v1/cart_items';
  static const String favorites = '/rest/v1/favorites';
  static const String orders = '/rest/v1/orders';
  static const String orderItems = '/rest/v1/order_items';
  static const String addresses = '/rest/v1/addresses';
  static const String profiles = '/rest/v1/profiles';
  static const String appSettings = '/rest/v1/app_settings';
  static const String notifications = '/rest/v1/notifications';
  static const String replacementRequests = '/rest/v1/replacement_requests';
  static const String replacementStatusLog = '/rest/v1/replacement_status_log';
  static const String rpcAddCartItem = '/rest/v1/rpc/add_cart_item';
  static const String rpcRegisterDeviceToken = '/rest/v1/rpc/register_device_token';
  static const String rpcLogNotificationEvent = '/rest/v1/rpc/log_notification_event';
  static const String rpcAdminBroadcastNotification = '/rest/v1/rpc/admin_broadcast_notification';
  static const String rpcAdminBroadcastAudienceCount = '/rest/v1/rpc/admin_broadcast_audience_count';
  static const String rpcAdminDeleteUser = '/rest/v1/rpc/admin_delete_user';
  static const String rpcAdminSetUserRole = '/rest/v1/rpc/admin_set_user_role';
  static const String rpcAdminGetUsersList = '/rest/v1/rpc/admin_get_users_list';
  static const String bannerComments = '/rest/v1/banner_comments';
  static const String bannerLikes = '/rest/v1/banner_likes';
  static const String rpcAdminSetUserBlocked = '/rest/v1/rpc/admin_set_user_blocked';
  static const String authUser = '/auth/v1/user';
  static const String authOtp = '/auth/v1/otp';
  static const String authVerify = '/auth/v1/verify';
  static const String apiCommentNotify = 'https://maktabali.com/api/banner-comments/notify';
}
