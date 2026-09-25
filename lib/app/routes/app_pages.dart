import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/splash/views/splash_view.dart';
import '../../modules/splash/controllers/splash_controller.dart';
import '../../modules/main_nav/views/main_nav_view.dart';
import '../../modules/main_nav/controllers/main_nav_controller.dart';
import '../../modules/home/views/home_view.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/products/views/products_view.dart';
import '../../modules/products/controllers/products_controller.dart';
import '../../modules/product_details/views/product_details_view.dart';
import '../../modules/product_details/controllers/product_details_controller.dart';
import '../../modules/cart/views/cart_view.dart';
import '../../modules/checkout/views/checkout_view.dart';
import '../../modules/orders/views/orders_view.dart';
import '../../modules/favorites/views/favorites_view.dart';
import '../../modules/search/views/search_view.dart';
import '../../modules/offline/views/offline_view.dart';
import '../../modules/auth/views/login_view.dart';
import '../../modules/about/views/about_view.dart';
import '../../modules/legal/views/privacy_view.dart';
import '../../modules/legal/views/terms_view.dart';
import '../../modules/addresses/views/addresses_view.dart';
import '../../modules/notifications/views/notifications_view.dart';
import '../../modules/notifications/views/broadcast_detail_view.dart';
import '../../modules/replacements/views/replacements_view.dart';
import '../../modules/admin/views/admin_view.dart';
import '../../modules/admin/views/archived_orders_view.dart';
import '../../modules/force_update/views/force_update_view.dart';
import '../../modules/reels/views/reels_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: BindingsBuilder(() {
        Get.put<SplashController>(SplashController());
      }),
    ),
    GetPage(
      name: AppRoutes.mainNav,
      page: () => const MainNavView(),
      binding: BindingsBuilder(() {
        Get.put<MainNavController>(MainNavController());
        Get.put<HomeController>(HomeController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomeView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<HomeController>(() => HomeController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.products,
      page: () => const ProductsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductsController>(() => ProductsController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.productDetails,
      page: () => const ProductDetailsView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ProductDetailsController>(() => ProductDetailsController());
      }),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => const CartView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.checkout,
      page: () => const CheckoutView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.orders,
      page: () => const OrdersView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.favorites,
      page: () => const FavoritesView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.search,
      page: () => const SearchView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.offline,
      page: () => const OfflineView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.about,
      page: () => const AboutView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.privacy,
      page: () => const PrivacyView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.terms,
      page: () => const TermsView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.addresses,
      page: () => const AddressesView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.replacements,
      page: () => const ReplacementsView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.forceUpdate,
      page: () => const ForceUpdateView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.reels,
      page: () => const ReelsView(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.broadcastDetail,
      page: () => const BroadcastDetailView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.archivedOrders,
      page: () => const ArchivedOrdersView(),
      transition: Transition.fade,
    ),
    GetPage(
      name: '/auth',
      page: () => const SizedBox.shrink(),
      transition: Transition.fade,
    ),
  ];
}
