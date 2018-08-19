import 'package:flutter/material.dart';
import 'package:zoomable_image/zoomable_image.dart';
import 'dart:async';

class ScrollGallery extends StatefulWidget {
  final double height;
  final double imageHeight;
  final double thumbnailSize;
  final List<ImageProvider> imageProviders;
  final BoxFit fit;
  final Duration interval;
  final Color borderColor;

  ScrollGallery(this.imageProviders,
    {
      this.height: 400.0,
      this.imageHeight : 250.0,
      this.thumbnailSize : 48.0,
      this.fit,
      this.interval,
      this.borderColor : Colors.red});

  @override
  _ScrollGalleryState createState() => _ScrollGalleryState();
}

class _ScrollGalleryState extends State<ScrollGallery>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  PageController _pageController;
  Timer _timer;
  int _currentIndex = 0;
  bool _reverse = false;

  int _loading = 0;

  @override
  void initState() {
    _scrollController = new ScrollController();
    _pageController = new PageController();

    if (widget.imageProviders.length > 1 && widget.interval != null) {
      _timer = new Timer.periodic(widget.interval, (_) {
        if (_currentIndex == widget.imageProviders.length - 1) {
          _reverse = true;
        }
        if (_currentIndex == 0) {
          _reverse = false;
        }

        if (_reverse) {
          _pageController?.previousPage(
              duration: const Duration(milliseconds: 500), curve: Curves.ease);
        } else {
          _pageController?.nextPage(
              duration: const Duration(milliseconds: 500), curve: Curves.ease);
        }
      });
    }

    widget.imageProviders.forEach((image) =>
      image.resolve(new ImageConfiguration()).addListener((i, b) {
        if (mounted) {
          setState(() {
            _loading++;
          });
        }
      })
    );
    
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController?.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
      double itemSize =
          (widget.thumbnailSize != null ? widget.thumbnailSize : 48.0) + 8.0;
      _scrollController?.animateTo(itemSize * index / 2,
          duration: const Duration(milliseconds: 200), curve: Curves.ease);
    });
  }

  Widget _buildImagePageView() {
    return Expanded(
        child: new PageView(
      onPageChanged: _onPageChanged,
      controller: _pageController,
      children: widget.imageProviders.map((image) {
        return new GestureDetector(
          onTap: () { 
            Navigator.of(context).push(new MaterialPageRoute<Null>(builder: (BuildContext context) {
              return new Scaffold(
                appBar: new AppBar(
                  title: const Text('Image'),
                  backgroundColor: new Color(0xFF000000),
                ),
                body: new ZoomableImage(
                  image,
                  backgroundColor: Colors.black,
                  placeholder: new Center(child: new CircularProgressIndicator()),
                ),
              );
            }));                      
          },
          child: new Image(
            fit: widget.fit != null ? widget.fit : null,
            image: image,
            height: widget.imageHeight
          ),
        );
      }).toList(),
    ));
  }

  void _selectImage(int index) {
    setState(() {
      _pageController?.animateToPage(index,
          duration: const Duration(milliseconds: 500), curve: Curves.ease);
    });
  }

  Widget _buildImageThumbnail() {
    var _thumbnailSize = widget.thumbnailSize;

    return new Container(
      height: _thumbnailSize,
      child: new ListView.builder(
        controller: _scrollController,
        itemCount: widget.imageProviders.length,
        scrollDirection: Axis.horizontal,
        itemBuilder: (BuildContext context, int index) {
          var _decoration = new BoxDecoration(
            border: new Border.all(color: _currentIndex == index ? widget.borderColor : Colors.white, width: 2.0),
          );

          return new GestureDetector(
            onTap: () {
              _selectImage(index);
            },
            child: new Container(
              decoration: _decoration,
              margin: const EdgeInsets.only(left: 8.0),
              child: new Image(
                image: widget.imageProviders[index],
                fit: BoxFit.cover,
                width: _thumbnailSize,
                height: _thumbnailSize,
              ),
            ));
        },
      ));
  }

  bool notNull(Object o) => o != null;

  @override
  Widget build(BuildContext context) {
    double availableHeight = widget.height;
    bool displayThumbs = (widget.imageProviders.length > 1 && (availableHeight - widget.imageHeight)/2.0 > (widget.thumbnailSize + 20.0)) ? true : false;
    return Container(
        height: availableHeight,
        color: Colors.white,
        child: _loading != widget.imageProviders.length ? new Center (
          child: new Container(
            height: 40.0,
            width: 40.0,
            child: new CircularProgressIndicator(),
          ),
        ) : 
        new Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new SizedBox(height: (availableHeight - widget.imageHeight)/2.0),
            _buildImagePageView(),
            new SizedBox(height: (availableHeight - widget.imageHeight)/2.0 - (displayThumbs ? (widget.thumbnailSize + 10.0) : 0)),
            displayThumbs ? _buildImageThumbnail() : null,
            displayThumbs ? new SizedBox(height: 10.0) : null,
          ].where(notNull).toList(),
        ));
  }
}
