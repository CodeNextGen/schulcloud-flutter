import 'package:banners/banners.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:schulcloud/app/app.dart';
import 'package:schulcloud/sign_in/sign_in.dart';

const _bannerPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 4);

class OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BannerScaffold(
      backgroundColor: context.theme.errorColor.withOpacity(0.5),
      body: Padding(
        padding: _bannerPadding,
        child: Text(context.s.app_error_noConnection),
      ),
    );
  }
}

class TokenExpiredBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BannerScaffold(
      backgroundColor: Colors.orange.withOpacity(0.5),
      body: Padding(
        padding: _bannerPadding,
        child: Row(
          children: <Widget>[
            Expanded(child: Text(context.s.app_error_tokenExpired)),
            SizedBox(width: 16),
            IconButton(
              onPressed: () => signOut(context),
              icon: SvgPicture.asset(
                'assets/icon_signOut.svg',
                color: context.theme.contrastColor,
                width: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
