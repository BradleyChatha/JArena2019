// Generated on Dec  9 2018 at 19:15:17 with jarena:generator
module jarena.graphics.colours;
public import arsd.colour;
abstract class Colours
{
	private static Colour[string] _colours;
	public static @nogc @safe nothrow pure const{
	static Colour abbey() { return Colour(76, 79, 86, 255); }
	static Colour acadia() { return Colour(27, 20, 4, 255); }
	static Colour acapulco() { return Colour(124, 176, 161, 255); }
	static Colour acorn() { return Colour(106, 93, 27, 255); }
	static Colour aeroBlue() { return Colour(201, 255, 229, 255); }
	static Colour affair() { return Colour(113, 70, 147, 255); }
	static Colour afghanTan() { return Colour(134, 86, 10, 255); }
	static Colour akaroa() { return Colour(212, 196, 168, 255); }
	static Colour alabaster() { return Colour(255, 255, 255, 255); }
	static Colour albescentWhite() { return Colour(245, 233, 211, 255); }
	static Colour alertTan() { return Colour(155, 71, 3, 255); }
	static Colour allports() { return Colour(0, 118, 163, 255); }
	static Colour almondFrost() { return Colour(144, 123, 113, 255); }
	static Colour alpine() { return Colour(175, 143, 44, 255); }
	static Colour alto() { return Colour(219, 219, 219, 255); }
	static Colour aluminium() { return Colour(169, 172, 182, 255); }
	static Colour amazon() { return Colour(59, 122, 87, 255); }
	static Colour americano() { return Colour(135, 117, 110, 255); }
	static Colour amethystSmoke() { return Colour(163, 151, 180, 255); }
	static Colour amour() { return Colour(249, 234, 243, 255); }
	static Colour amulet() { return Colour(123, 159, 128, 255); }
	static Colour anakiwa() { return Colour(157, 229, 255, 255); }
	static Colour antiqueBrass() { return Colour(112, 74, 7, 255); }
	static Colour anzac() { return Colour(224, 182, 70, 255); }
	static Colour apache() { return Colour(223, 190, 111, 255); }
	static Colour apple() { return Colour(79, 168, 61, 255); }
	static Colour appleBlossom() { return Colour(175, 77, 67, 255); }
	static Colour appleGreen() { return Colour(226, 243, 236, 255); }
	static Colour apricot() { return Colour(235, 147, 115, 255); }
	static Colour apricotWhite() { return Colour(255, 254, 236, 255); }
	static Colour aqua() { return Colour(161, 218, 215, 255); }
	static Colour aquaHaze() { return Colour(237, 245, 245, 255); }
	static Colour aquaSpring() { return Colour(234, 249, 245, 255); }
	static Colour aquaSqueeze() { return Colour(232, 245, 242, 255); }
	static Colour aquamarine() { return Colour(1, 75, 67, 255); }
	static Colour arapawa() { return Colour(17, 12, 108, 255); }
	static Colour armadillo() { return Colour(67, 62, 55, 255); }
	static Colour arrowtown() { return Colour(148, 135, 113, 255); }
	static Colour ash() { return Colour(198, 195, 181, 255); }
	static Colour ashBrown() { return Colour(46, 25, 5, 255); }
	static Colour asphalt() { return Colour(19, 10, 6, 255); }
	static Colour astra() { return Colour(250, 234, 185, 255); }
	static Colour astral() { return Colour(50, 125, 160, 255); }
	static Colour astronaut() { return Colour(40, 58, 119, 255); }
	static Colour astronautBlue() { return Colour(1, 62, 98, 255); }
	static Colour athensGrey() { return Colour(238, 240, 243, 255); }
	static Colour athsSpecial() { return Colour(236, 235, 206, 255); }
	static Colour atlantis() { return Colour(151, 205, 45, 255); }
	static Colour atoll() { return Colour(10, 111, 117, 255); }
	static Colour atomic() { return Colour(49, 68, 89, 255); }
	static Colour auChico() { return Colour(151, 96, 93, 255); }
	static Colour aubergine() { return Colour(59, 9, 16, 255); }
	static Colour australianMint() { return Colour(245, 255, 190, 255); }
	static Colour avocado() { return Colour(136, 141, 101, 255); }
	static Colour axolotl() { return Colour(78, 102, 73, 255); }
	static Colour azalea() { return Colour(247, 200, 218, 255); }
	static Colour aztec() { return Colour(13, 28, 25, 255); }
	static Colour azure() { return Colour(49, 91, 161, 255); }
	static Colour bahamaBlue() { return Colour(2, 99, 149, 255); }
	static Colour bahia() { return Colour(165, 203, 12, 255); }
	static Colour bajaWhite() { return Colour(255, 248, 209, 255); }
	static Colour baliHai() { return Colour(133, 159, 175, 255); }
	static Colour balticSea() { return Colour(42, 38, 48, 255); }
	static Colour bamboo() { return Colour(218, 99, 4, 255); }
	static Colour bandicoot() { return Colour(133, 132, 112, 255); }
	static Colour banjul() { return Colour(19, 10, 6, 255); }
	static Colour barberry() { return Colour(222, 215, 23, 255); }
	static Colour barleyCorn() { return Colour(166, 139, 91, 255); }
	static Colour barleyWhite() { return Colour(255, 244, 206, 255); }
	static Colour barossa() { return Colour(68, 1, 45, 255); }
	static Colour bastille() { return Colour(41, 33, 48, 255); }
	static Colour battleshipGrey() { return Colour(130, 143, 114, 255); }
	static Colour bayLeaf() { return Colour(125, 169, 141, 255); }
	static Colour bayofMany() { return Colour(39, 58, 129, 255); }
	static Colour bazaar() { return Colour(152, 119, 123, 255); }
	static Colour bean() { return Colour(61, 12, 2, 255); }
	static Colour beautyBush() { return Colour(238, 193, 190, 255); }
	static Colour beeswax() { return Colour(254, 242, 199, 255); }
	static Colour bermuda() { return Colour(125, 216, 198, 255); }
	static Colour bermudaGrey() { return Colour(107, 139, 162, 255); }
	static Colour berylGreen() { return Colour(222, 229, 192, 255); }
	static Colour bianca() { return Colour(252, 251, 243, 255); }
	static Colour bigStone() { return Colour(22, 42, 64, 255); }
	static Colour bilbao() { return Colour(50, 124, 20, 255); }
	static Colour bilobaFlower() { return Colour(178, 161, 234, 255); }
	static Colour birch() { return Colour(55, 48, 33, 255); }
	static Colour birdFlower() { return Colour(212, 205, 22, 255); }
	static Colour biscay() { return Colour(27, 49, 98, 255); }
	static Colour bismark() { return Colour(73, 113, 131, 255); }
	static Colour bisonHide() { return Colour(193, 183, 164, 255); }
	static Colour bitter() { return Colour(134, 137, 116, 255); }
	static Colour bitterLemon() { return Colour(202, 224, 13, 255); }
	static Colour bizarre() { return Colour(238, 222, 218, 255); }
	static Colour blackBean() { return Colour(8, 25, 16, 255); }
	static Colour blackForest() { return Colour(11, 19, 4, 255); }
	static Colour blackHaze() { return Colour(246, 247, 247, 255); }
	static Colour blackMagic() { return Colour(37, 23, 6, 255); }
	static Colour blackMarlin() { return Colour(62, 44, 28, 255); }
	static Colour blackPearl() { return Colour(4, 19, 34, 255); }
	static Colour blackPepper() { return Colour(14, 14, 24, 255); }
	static Colour blackRock() { return Colour(13, 3, 50, 255); }
	static Colour blackRose() { return Colour(103, 3, 45, 255); }
	static Colour blackRussian() { return Colour(10, 0, 28, 255); }
	static Colour blackSqueeze() { return Colour(242, 250, 250, 255); }
	static Colour blackWhite() { return Colour(255, 254, 246, 255); }
	static Colour blackberry() { return Colour(77, 1, 53, 255); }
	static Colour blackcurrant() { return Colour(50, 41, 58, 255); }
	static Colour blackwood() { return Colour(38, 17, 5, 255); }
	static Colour blanc() { return Colour(245, 233, 211, 255); }
	static Colour bleachWhite() { return Colour(254, 243, 216, 255); }
	static Colour bleachedCedar() { return Colour(44, 33, 51, 255); }
	static Colour blossom() { return Colour(220, 180, 188, 255); }
	static Colour blueBark() { return Colour(4, 19, 34, 255); }
	static Colour blueBayoux() { return Colour(73, 102, 121, 255); }
	static Colour blueBell() { return Colour(34, 8, 120, 255); }
	static Colour blueChalk() { return Colour(241, 233, 255, 255); }
	static Colour blueCharcoal() { return Colour(1, 13, 26, 255); }
	static Colour blueChill() { return Colour(12, 137, 144, 255); }
	static Colour blueDiamond() { return Colour(56, 4, 116, 255); }
	static Colour blueDianne() { return Colour(32, 72, 82, 255); }
	static Colour blueGem() { return Colour(44, 14, 140, 255); }
	static Colour blueHaze() { return Colour(191, 190, 216, 255); }
	static Colour blueLagoon() { return Colour(1, 121, 135, 255); }
	static Colour blueMarguerite() { return Colour(118, 102, 198, 255); }
	static Colour blueRomance() { return Colour(210, 246, 222, 255); }
	static Colour blueSmoke() { return Colour(116, 136, 129, 255); }
	static Colour blueStone() { return Colour(1, 97, 98, 255); }
	static Colour blueWhale() { return Colour(4, 46, 76, 255); }
	static Colour blueZodiac() { return Colour(19, 38, 77, 255); }
	static Colour blumine() { return Colour(24, 88, 122, 255); }
	static Colour blush() { return Colour(180, 70, 104, 255); }
	static Colour bokaraGrey() { return Colour(28, 18, 8, 255); }
	static Colour bombay() { return Colour(175, 177, 184, 255); }
	static Colour bonJour() { return Colour(229, 224, 225, 255); }
	static Colour bondiBlue() { return Colour(2, 71, 142, 255); }
	static Colour bone() { return Colour(228, 209, 192, 255); }
	static Colour bordeaux() { return Colour(92, 1, 32, 255); }
	static Colour bossanova() { return Colour(78, 42, 90, 255); }
	static Colour bostonBlue() { return Colour(59, 145, 180, 255); }
	static Colour botticelli() { return Colour(199, 221, 229, 255); }
	static Colour bottleGreen() { return Colour(9, 54, 36, 255); }
	static Colour boulder() { return Colour(122, 122, 122, 255); }
	static Colour bouquet() { return Colour(174, 128, 158, 255); }
	static Colour bourbon() { return Colour(186, 111, 30, 255); }
	static Colour bracken() { return Colour(74, 42, 4, 255); }
	static Colour brandy() { return Colour(222, 193, 150, 255); }
	static Colour brandyPunch() { return Colour(205, 132, 41, 255); }
	static Colour brandyRose() { return Colour(187, 137, 131, 255); }
	static Colour brazil() { return Colour(136, 98, 33, 255); }
	static Colour breakerBay() { return Colour(93, 161, 159, 255); }
	static Colour bridalHeath() { return Colour(255, 250, 244, 255); }
	static Colour bridesmaid() { return Colour(254, 240, 236, 255); }
	static Colour brightGrey() { return Colour(60, 65, 81, 255); }
	static Colour brightRed() { return Colour(177, 0, 0, 255); }
	static Colour brightSun() { return Colour(254, 211, 60, 255); }
	static Colour bronco() { return Colour(171, 161, 150, 255); }
	static Colour bronze() { return Colour(63, 33, 9, 255); }
	static Colour bronzeOlive() { return Colour(78, 66, 12, 255); }
	static Colour bronzetone() { return Colour(77, 64, 15, 255); }
	static Colour broom() { return Colour(255, 236, 19, 255); }
	static Colour brownBramble() { return Colour(89, 40, 4, 255); }
	static Colour brownDerby() { return Colour(73, 38, 21, 255); }
	static Colour brownPod() { return Colour(64, 24, 1, 255); }
	static Colour bubbles() { return Colour(231, 254, 255, 255); }
	static Colour buccaneer() { return Colour(98, 47, 48, 255); }
	static Colour bud() { return Colour(168, 174, 156, 255); }
	static Colour buddhaGold() { return Colour(193, 160, 4, 255); }
	static Colour bulgarianRose() { return Colour(72, 6, 7, 255); }
	static Colour bullShot() { return Colour(134, 77, 30, 255); }
	static Colour bunker() { return Colour(13, 17, 23, 255); }
	static Colour bunting() { return Colour(21, 31, 76, 255); }
	static Colour burgundy() { return Colour(119, 15, 5, 255); }
	static Colour burnham() { return Colour(0, 46, 32, 255); }
	static Colour burningSand() { return Colour(217, 147, 118, 255); }
	static Colour burntCrimson() { return Colour(101, 0, 11, 255); }
	static Colour bush() { return Colour(13, 46, 28, 255); }
	static Colour buttercup() { return Colour(243, 173, 22, 255); }
	static Colour butteredRum() { return Colour(161, 117, 13, 255); }
	static Colour butterflyBush() { return Colour(98, 78, 154, 255); }
	static Colour buttermilk() { return Colour(255, 241, 181, 255); }
	static Colour butteryWhite() { return Colour(255, 252, 234, 255); }
	static Colour cabSav() { return Colour(77, 10, 24, 255); }
	static Colour cabaret() { return Colour(217, 73, 114, 255); }
	static Colour cabbagePont() { return Colour(63, 76, 58, 255); }
	static Colour cactus() { return Colour(88, 113, 86, 255); }
	static Colour cadillac() { return Colour(176, 76, 106, 255); }
	static Colour cafeRoyale() { return Colour(111, 68, 12, 255); }
	static Colour calico() { return Colour(224, 192, 149, 255); }
	static Colour california() { return Colour(254, 157, 4, 255); }
	static Colour calypso() { return Colour(49, 114, 141, 255); }
	static Colour camarone() { return Colour(0, 88, 26, 255); }
	static Colour camelot() { return Colour(137, 52, 86, 255); }
	static Colour cameo() { return Colour(217, 185, 155, 255); }
	static Colour camouflage() { return Colour(60, 57, 16, 255); }
	static Colour canCan() { return Colour(213, 145, 164, 255); }
	static Colour canary() { return Colour(243, 251, 98, 255); }
	static Colour candlelight() { return Colour(252, 217, 23, 255); }
	static Colour cannonBlack() { return Colour(37, 23, 6, 255); }
	static Colour cannonPink() { return Colour(137, 67, 103, 255); }
	static Colour canvas() { return Colour(168, 165, 137, 255); }
	static Colour capeCod() { return Colour(60, 68, 67, 255); }
	static Colour capeHoney() { return Colour(254, 229, 172, 255); }
	static Colour capePalliser() { return Colour(162, 102, 69, 255); }
	static Colour caper() { return Colour(220, 237, 180, 255); }
	static Colour capri() { return Colour(6, 42, 120, 255); }
	static Colour caramel() { return Colour(255, 221, 175, 255); }
	static Colour cararra() { return Colour(238, 238, 232, 255); }
	static Colour cardinGreen() { return Colour(1, 54, 28, 255); }
	static Colour cardinal() { return Colour(140, 5, 94, 255); }
	static Colour careysPink() { return Colour(210, 158, 170, 255); }
	static Colour carissma() { return Colour(234, 136, 168, 255); }
	static Colour carla() { return Colour(243, 255, 216, 255); }
	static Colour carnabyTan() { return Colour(92, 46, 1, 255); }
	static Colour carouselPink() { return Colour(249, 224, 237, 255); }
	static Colour casablanca() { return Colour(248, 184, 83, 255); }
	static Colour casal() { return Colour(47, 97, 104, 255); }
	static Colour cascade() { return Colour(139, 169, 165, 255); }
	static Colour cashmere() { return Colour(230, 190, 165, 255); }
	static Colour casper() { return Colour(173, 190, 209, 255); }
	static Colour castro() { return Colour(82, 0, 31, 255); }
	static Colour catalinaBlue() { return Colour(6, 42, 120, 255); }
	static Colour catskillWhite() { return Colour(238, 246, 247, 255); }
	static Colour cavernPink() { return Colour(227, 190, 190, 255); }
	static Colour ceSoir() { return Colour(151, 113, 181, 255); }
	static Colour cedar() { return Colour(62, 28, 20, 255); }
	static Colour cedarWoodFinish() { return Colour(113, 26, 0, 255); }
	static Colour celery() { return Colour(184, 194, 93, 255); }
	static Colour celeste() { return Colour(209, 210, 202, 255); }
	static Colour cello() { return Colour(30, 56, 91, 255); }
	static Colour celtic() { return Colour(22, 50, 34, 255); }
	static Colour cement() { return Colour(141, 118, 98, 255); }
	static Colour ceramic() { return Colour(252, 255, 249, 255); }
	static Colour chablis() { return Colour(255, 244, 243, 255); }
	static Colour chaletGreen() { return Colour(81, 110, 61, 255); }
	static Colour chalky() { return Colour(238, 215, 148, 255); }
	static Colour chambray() { return Colour(53, 78, 140, 255); }
	static Colour chamois() { return Colour(237, 220, 177, 255); }
	static Colour champagne() { return Colour(250, 236, 204, 255); }
	static Colour chantilly() { return Colour(248, 195, 223, 255); }
	static Colour charade() { return Colour(41, 41, 55, 255); }
	static Colour chardon() { return Colour(255, 243, 241, 255); }
	static Colour chardonnay() { return Colour(255, 205, 140, 255); }
	static Colour charlotte() { return Colour(186, 238, 249, 255); }
	static Colour charm() { return Colour(212, 116, 148, 255); }
	static Colour chateauGreen() { return Colour(64, 168, 96, 255); }
	static Colour chatelle() { return Colour(189, 179, 199, 255); }
	static Colour chathamsBlue() { return Colour(23, 85, 121, 255); }
	static Colour chelseaCucumber() { return Colour(131, 170, 93, 255); }
	static Colour chelseaGem() { return Colour(158, 83, 2, 255); }
	static Colour chenin() { return Colour(223, 205, 111, 255); }
	static Colour cherokee() { return Colour(252, 218, 152, 255); }
	static Colour cherryPie() { return Colour(42, 3, 89, 255); }
	static Colour cherrywood() { return Colour(101, 26, 20, 255); }
	static Colour cherub() { return Colour(248, 217, 233, 255); }
	static Colour chetwodeBlue() { return Colour(133, 129, 217, 255); }
	static Colour chicago() { return Colour(93, 92, 88, 255); }
	static Colour chiffon() { return Colour(241, 255, 200, 255); }
	static Colour chileanFire() { return Colour(247, 119, 3, 255); }
	static Colour chileanHeath() { return Colour(255, 253, 230, 255); }
	static Colour chinaIvory() { return Colour(252, 255, 231, 255); }
	static Colour chino() { return Colour(206, 199, 167, 255); }
	static Colour chinook() { return Colour(168, 227, 189, 255); }
	static Colour chocolate() { return Colour(55, 2, 2, 255); }
	static Colour christalle() { return Colour(51, 3, 107, 255); }
	static Colour christi() { return Colour(103, 167, 18, 255); }
	static Colour christine() { return Colour(231, 115, 10, 255); }
	static Colour chromeWhite() { return Colour(232, 241, 212, 255); }
	static Colour cigar() { return Colour(119, 63, 26, 255); }
	static Colour cinder() { return Colour(14, 14, 24, 255); }
	static Colour cinderella() { return Colour(253, 225, 220, 255); }
	static Colour cinnamon() { return Colour(123, 63, 0, 255); }
	static Colour cioccolato() { return Colour(85, 40, 12, 255); }
	static Colour citrineWhite() { return Colour(250, 247, 214, 255); }
	static Colour citron() { return Colour(158, 169, 31, 255); }
	static Colour citrus() { return Colour(161, 197, 10, 255); }
	static Colour clairvoyant() { return Colour(72, 6, 86, 255); }
	static Colour clamShell() { return Colour(212, 182, 175, 255); }
	static Colour claret() { return Colour(127, 23, 52, 255); }
	static Colour classicRose() { return Colour(251, 204, 231, 255); }
	static Colour clayCreek() { return Colour(138, 131, 96, 255); }
	static Colour clearDay() { return Colour(233, 255, 253, 255); }
	static Colour clementine() { return Colour(233, 110, 0, 255); }
	static Colour clinker() { return Colour(55, 29, 9, 255); }
	static Colour cloud() { return Colour(199, 196, 191, 255); }
	static Colour cloudBurst() { return Colour(32, 46, 84, 255); }
	static Colour cloudy() { return Colour(172, 165, 159, 255); }
	static Colour clover() { return Colour(56, 73, 16, 255); }
	static Colour cobalt() { return Colour(6, 42, 120, 255); }
	static Colour cocoaBean() { return Colour(72, 28, 28, 255); }
	static Colour cocoaBrown() { return Colour(48, 31, 30, 255); }
	static Colour coconutCream() { return Colour(248, 247, 220, 255); }
	static Colour codGrey() { return Colour(11, 11, 11, 255); }
	static Colour coffee() { return Colour(112, 101, 85, 255); }
	static Colour coffeeBean() { return Colour(42, 20, 14, 255); }
	static Colour cognac() { return Colour(159, 56, 29, 255); }
	static Colour cola() { return Colour(63, 37, 0, 255); }
	static Colour coldPurple() { return Colour(171, 160, 217, 255); }
	static Colour coldTurkey() { return Colour(206, 186, 186, 255); }
	static Colour colonialWhite() { return Colour(255, 237, 188, 255); }
	static Colour comet() { return Colour(92, 93, 117, 255); }
	static Colour como() { return Colour(81, 124, 102, 255); }
	static Colour conch() { return Colour(201, 217, 210, 255); }
	static Colour concord() { return Colour(124, 123, 122, 255); }
	static Colour concrete() { return Colour(242, 242, 242, 255); }
	static Colour confetti() { return Colour(233, 215, 90, 255); }
	static Colour congoBrown() { return Colour(89, 55, 55, 255); }
	static Colour conifer() { return Colour(172, 221, 77, 255); }
	static Colour contessa() { return Colour(198, 114, 107, 255); }
	static Colour copperCanyon() { return Colour(126, 58, 21, 255); }
	static Colour copperRust() { return Colour(148, 71, 71, 255); }
	static Colour coral() { return Colour(199, 188, 162, 255); }
	static Colour coralCandy() { return Colour(255, 220, 214, 255); }
	static Colour coralTree() { return Colour(168, 107, 107, 255); }
	static Colour corduroy() { return Colour(96, 110, 104, 255); }
	static Colour coriander() { return Colour(196, 208, 176, 255); }
	static Colour cork() { return Colour(64, 41, 29, 255); }
	static Colour corn() { return Colour(231, 191, 5, 255); }
	static Colour cornField() { return Colour(248, 250, 205, 255); }
	static Colour cornHarvest() { return Colour(139, 107, 11, 255); }
	static Colour cornflower() { return Colour(255, 176, 172, 255); }
	static Colour corvette() { return Colour(250, 211, 162, 255); }
	static Colour cosmic() { return Colour(118, 57, 93, 255); }
	static Colour cosmos() { return Colour(255, 216, 217, 255); }
	static Colour costaDelSol() { return Colour(97, 93, 48, 255); }
	static Colour cottonSeed() { return Colour(194, 189, 182, 255); }
	static Colour countyGreen() { return Colour(1, 55, 26, 255); }
	static Colour coveGrey() { return Colour(5, 22, 87, 255); }
	static Colour cowboy() { return Colour(77, 40, 45, 255); }
	static Colour crabApple() { return Colour(160, 39, 18, 255); }
	static Colour crail() { return Colour(185, 81, 64, 255); }
	static Colour cranberry() { return Colour(182, 49, 108, 255); }
	static Colour craterBrown() { return Colour(70, 36, 37, 255); }
	static Colour creamBrulee() { return Colour(255, 229, 160, 255); }
	static Colour creamCan() { return Colour(245, 200, 92, 255); }
	static Colour cremeDeBanane() { return Colour(255, 252, 153, 255); }
	static Colour creole() { return Colour(30, 15, 4, 255); }
	static Colour crete() { return Colour(115, 120, 41, 255); }
	static Colour crocodile() { return Colour(115, 109, 88, 255); }
	static Colour crownofThorns() { return Colour(119, 31, 31, 255); }
	static Colour crowshead() { return Colour(28, 18, 8, 255); }
	static Colour cruise() { return Colour(181, 236, 223, 255); }
	static Colour crusoe() { return Colour(0, 72, 22, 255); }
	static Colour crusta() { return Colour(253, 123, 51, 255); }
	static Colour cubanTan() { return Colour(42, 20, 14, 255); }
	static Colour cumin() { return Colour(146, 67, 33, 255); }
	static Colour cumulus() { return Colour(253, 255, 213, 255); }
	static Colour cupid() { return Colour(251, 190, 218, 255); }
	static Colour curiousBlue() { return Colour(37, 150, 209, 255); }
	static Colour cuttySark() { return Colour(80, 118, 114, 255); }
	static Colour cyprus() { return Colour(0, 62, 64, 255); }
	static Colour daintree() { return Colour(1, 39, 49, 255); }
	static Colour dairyCream() { return Colour(249, 228, 188, 255); }
	static Colour daisyBush() { return Colour(79, 35, 152, 255); }
	static Colour dallas() { return Colour(110, 75, 38, 255); }
	static Colour danube() { return Colour(96, 147, 209, 255); }
	static Colour darkEbony() { return Colour(60, 32, 5, 255); }
	static Colour darkOak() { return Colour(97, 39, 24, 255); }
	static Colour darkRimu() { return Colour(95, 61, 38, 255); }
	static Colour darkRum() { return Colour(65, 32, 16, 255); }
	static Colour darkSlate() { return Colour(57, 72, 81, 255); }
	static Colour darkTan() { return Colour(102, 16, 16, 255); }
	static Colour dawn() { return Colour(166, 162, 154, 255); }
	static Colour dawnPink() { return Colour(243, 233, 229, 255); }
	static Colour deYork() { return Colour(122, 196, 136, 255); }
	static Colour deco() { return Colour(210, 218, 151, 255); }
	static Colour deepBlush() { return Colour(228, 118, 152, 255); }
	static Colour deepBronze() { return Colour(74, 48, 4, 255); }
	static Colour deepCove() { return Colour(5, 16, 64, 255); }
	static Colour deepFir() { return Colour(0, 41, 0, 255); }
	static Colour deepKoamaru() { return Colour(27, 18, 123, 255); }
	static Colour deepOak() { return Colour(65, 32, 16, 255); }
	static Colour deepSea() { return Colour(1, 130, 107, 255); }
	static Colour deepTeal() { return Colour(0, 53, 50, 255); }
	static Colour delRio() { return Colour(176, 154, 149, 255); }
	static Colour dell() { return Colour(57, 100, 19, 255); }
	static Colour delta() { return Colour(164, 164, 157, 255); }
	static Colour deluge() { return Colour(117, 99, 168, 255); }
	static Colour derby() { return Colour(255, 238, 216, 255); }
	static Colour desert() { return Colour(174, 96, 32, 255); }
	static Colour desertStorm() { return Colour(248, 248, 247, 255); }
	static Colour dew() { return Colour(234, 255, 254, 255); }
	static Colour diSerria() { return Colour(219, 153, 94, 255); }
	static Colour diesel() { return Colour(19, 0, 0, 255); }
	static Colour dingley() { return Colour(93, 119, 71, 255); }
	static Colour disco() { return Colour(135, 21, 80, 255); }
	static Colour dixie() { return Colour(226, 148, 24, 255); }
	static Colour dolly() { return Colour(249, 255, 139, 255); }
	static Colour dolphin() { return Colour(100, 96, 119, 255); }
	static Colour domino() { return Colour(142, 119, 94, 255); }
	static Colour donJuan() { return Colour(93, 76, 81, 255); }
	static Colour donkeyBrown() { return Colour(166, 146, 121, 255); }
	static Colour dorado() { return Colour(107, 87, 85, 255); }
	static Colour doubleColonialWhite() { return Colour(238, 227, 173, 255); }
	static Colour doublePearlLusta() { return Colour(252, 244, 208, 255); }
	static Colour doubleSpanishWhite() { return Colour(230, 215, 185, 255); }
	static Colour doveGrey() { return Colour(109, 108, 108, 255); }
	static Colour downriver() { return Colour(9, 34, 86, 255); }
	static Colour downy() { return Colour(111, 208, 197, 255); }
	static Colour driftwood() { return Colour(175, 135, 81, 255); }
	static Colour drover() { return Colour(253, 247, 173, 255); }
	static Colour dune() { return Colour(56, 53, 51, 255); }
	static Colour dustStorm() { return Colour(229, 204, 201, 255); }
	static Colour dustyGrey() { return Colour(168, 152, 155, 255); }
	static Colour dutchWhite() { return Colour(255, 248, 209, 255); }
	static Colour eagle() { return Colour(182, 186, 164, 255); }
	static Colour earlsGreen() { return Colour(201, 185, 59, 255); }
	static Colour earlyDawn() { return Colour(255, 249, 230, 255); }
	static Colour eastBay() { return Colour(65, 76, 125, 255); }
	static Colour eastSide() { return Colour(172, 145, 206, 255); }
	static Colour easternBlue() { return Colour(30, 154, 176, 255); }
	static Colour ebb() { return Colour(233, 227, 227, 255); }
	static Colour ebony() { return Colour(12, 11, 29, 255); }
	static Colour ebonyClay() { return Colour(38, 40, 59, 255); }
	static Colour echoBlue() { return Colour(175, 189, 217, 255); }
	static Colour eclipse() { return Colour(49, 28, 23, 255); }
	static Colour ecruWhite() { return Colour(245, 243, 229, 255); }
	static Colour ecstasy() { return Colour(250, 120, 20, 255); }
	static Colour eden() { return Colour(16, 88, 82, 255); }
	static Colour edgewater() { return Colour(200, 227, 215, 255); }
	static Colour edward() { return Colour(162, 174, 171, 255); }
	static Colour eggSour() { return Colour(255, 244, 221, 255); }
	static Colour eggWhite() { return Colour(255, 239, 193, 255); }
	static Colour elPaso() { return Colour(30, 23, 8, 255); }
	static Colour elSalva() { return Colour(143, 62, 51, 255); }
	static Colour elephant() { return Colour(18, 52, 71, 255); }
	static Colour elfGreen() { return Colour(8, 131, 112, 255); }
	static Colour elm() { return Colour(28, 124, 125, 255); }
	static Colour embers() { return Colour(160, 39, 18, 255); }
	static Colour eminence() { return Colour(108, 48, 130, 255); }
	static Colour emperor() { return Colour(81, 70, 73, 255); }
	static Colour empress() { return Colour(129, 115, 119, 255); }
	static Colour endeavour() { return Colour(0, 86, 167, 255); }
	static Colour energyYellow() { return Colour(248, 221, 92, 255); }
	static Colour englishHolly() { return Colour(2, 45, 21, 255); }
	static Colour englishWalnut() { return Colour(62, 43, 35, 255); }
	static Colour envy() { return Colour(139, 166, 144, 255); }
	static Colour equator() { return Colour(225, 188, 100, 255); }
	static Colour espresso() { return Colour(97, 39, 24, 255); }
	static Colour eternity() { return Colour(33, 26, 14, 255); }
	static Colour eucalyptus() { return Colour(39, 138, 91, 255); }
	static Colour eunry() { return Colour(207, 163, 157, 255); }
	static Colour eveningSea() { return Colour(2, 78, 70, 255); }
	static Colour everglade() { return Colour(28, 64, 46, 255); }
	static Colour fairPink() { return Colour(255, 239, 236, 255); }
	static Colour falcon() { return Colour(127, 98, 109, 255); }
	static Colour fantasy() { return Colour(250, 243, 240, 255); }
	static Colour fedora() { return Colour(121, 106, 120, 255); }
	static Colour feijoa() { return Colour(159, 221, 140, 255); }
	static Colour fern() { return Colour(10, 72, 13, 255); }
	static Colour fernFrond() { return Colour(101, 114, 32, 255); }
	static Colour ferra() { return Colour(112, 79, 80, 255); }
	static Colour festival() { return Colour(251, 233, 108, 255); }
	static Colour feta() { return Colour(240, 252, 234, 255); }
	static Colour fieryOrange() { return Colour(179, 82, 19, 255); }
	static Colour fijiGreen() { return Colour(101, 114, 32, 255); }
	static Colour finch() { return Colour(98, 102, 73, 255); }
	static Colour finlandia() { return Colour(85, 109, 86, 255); }
	static Colour finn() { return Colour(105, 45, 84, 255); }
	static Colour fiord() { return Colour(64, 81, 105, 255); }
	static Colour fire() { return Colour(170, 66, 3, 255); }
	static Colour fireBush() { return Colour(232, 153, 40, 255); }
	static Colour firefly() { return Colour(14, 42, 48, 255); }
	static Colour flamePea() { return Colour(218, 91, 56, 255); }
	static Colour flameRed() { return Colour(199, 3, 30, 255); }
	static Colour flamenco() { return Colour(255, 125, 7, 255); }
	static Colour flamingo() { return Colour(242, 85, 42, 255); }
	static Colour flax() { return Colour(123, 130, 101, 255); }
	static Colour flint() { return Colour(111, 106, 97, 255); }
	static Colour flirt() { return Colour(162, 0, 109, 255); }
	static Colour foam() { return Colour(216, 252, 250, 255); }
	static Colour fog() { return Colour(215, 208, 255, 255); }
	static Colour foggyGrey() { return Colour(203, 202, 182, 255); }
	static Colour forestGreen() { return Colour(24, 45, 9, 255); }
	static Colour forgetMeNot() { return Colour(255, 241, 238, 255); }
	static Colour fountainBlue() { return Colour(86, 180, 190, 255); }
	static Colour frangipani() { return Colour(255, 222, 179, 255); }
	static Colour frenchGrey() { return Colour(189, 189, 198, 255); }
	static Colour frenchLilac() { return Colour(236, 199, 238, 255); }
	static Colour frenchPass() { return Colour(189, 237, 253, 255); }
	static Colour friarGrey() { return Colour(128, 126, 121, 255); }
	static Colour fringyFlower() { return Colour(177, 226, 193, 255); }
	static Colour froly() { return Colour(245, 117, 132, 255); }
	static Colour frost() { return Colour(237, 245, 221, 255); }
	static Colour frostedMint() { return Colour(219, 255, 248, 255); }
	static Colour frostee() { return Colour(228, 246, 231, 255); }
	static Colour fruitSalad() { return Colour(79, 157, 93, 255); }
	static Colour fuchsia() { return Colour(122, 88, 193, 255); }
	static Colour fuego() { return Colour(190, 222, 13, 255); }
	static Colour fuelYellow() { return Colour(236, 169, 39, 255); }
	static Colour funBlue() { return Colour(25, 89, 168, 255); }
	static Colour funGreen() { return Colour(1, 109, 57, 255); }
	static Colour fuscousGrey() { return Colour(84, 83, 77, 255); }
	static Colour gableGreen() { return Colour(22, 53, 49, 255); }
	static Colour gallery() { return Colour(239, 239, 239, 255); }
	static Colour galliano() { return Colour(220, 178, 12, 255); }
	static Colour geebung() { return Colour(209, 143, 27, 255); }
	static Colour genoa() { return Colour(21, 115, 107, 255); }
	static Colour geraldine() { return Colour(251, 137, 137, 255); }
	static Colour geyser() { return Colour(212, 223, 226, 255); }
	static Colour ghost() { return Colour(199, 201, 213, 255); }
	static Colour gigas() { return Colour(82, 60, 148, 255); }
	static Colour gimblet() { return Colour(184, 181, 106, 255); }
	static Colour gin() { return Colour(232, 242, 235, 255); }
	static Colour ginFizz() { return Colour(255, 249, 226, 255); }
	static Colour givry() { return Colour(248, 228, 191, 255); }
	static Colour glacier() { return Colour(128, 179, 196, 255); }
	static Colour gladeGreen() { return Colour(97, 132, 95, 255); }
	static Colour goBen() { return Colour(114, 109, 78, 255); }
	static Colour goblin() { return Colour(61, 125, 82, 255); }
	static Colour goldDrop() { return Colour(241, 130, 0, 255); }
	static Colour goldTips() { return Colour(222, 186, 19, 255); }
	static Colour goldenBell() { return Colour(226, 137, 19, 255); }
	static Colour goldenDream() { return Colour(240, 213, 45, 255); }
	static Colour goldenFizz() { return Colour(245, 251, 61, 255); }
	static Colour goldenGlow() { return Colour(253, 226, 149, 255); }
	static Colour goldenSand() { return Colour(240, 219, 125, 255); }
	static Colour goldenTainoi() { return Colour(255, 204, 92, 255); }
	static Colour gondola() { return Colour(38, 20, 20, 255); }
	static Colour gordonsGreen() { return Colour(11, 17, 7, 255); }
	static Colour gorse() { return Colour(255, 241, 79, 255); }
	static Colour gossamer() { return Colour(6, 155, 129, 255); }
	static Colour gossip() { return Colour(210, 248, 176, 255); }
	static Colour gothic() { return Colour(109, 146, 161, 255); }
	static Colour governorBay() { return Colour(47, 60, 179, 255); }
	static Colour grainBrown() { return Colour(228, 213, 183, 255); }
	static Colour grandis() { return Colour(255, 211, 140, 255); }
	static Colour graniteGreen() { return Colour(141, 137, 116, 255); }
	static Colour grannyApple() { return Colour(213, 246, 227, 255); }
	static Colour grannySmith() { return Colour(132, 160, 160, 255); }
	static Colour grape() { return Colour(56, 26, 81, 255); }
	static Colour graphite() { return Colour(37, 22, 7, 255); }
	static Colour grassHopper() { return Colour(124, 118, 49, 255); }
	static Colour gravel() { return Colour(74, 68, 75, 255); }
	static Colour greenHouse() { return Colour(36, 80, 15, 255); }
	static Colour greenKelp() { return Colour(37, 49, 28, 255); }
	static Colour greenLeaf() { return Colour(67, 106, 13, 255); }
	static Colour greenMist() { return Colour(203, 211, 176, 255); }
	static Colour greenPea() { return Colour(29, 97, 66, 255); }
	static Colour greenSmoke() { return Colour(164, 175, 110, 255); }
	static Colour greenSpring() { return Colour(184, 193, 177, 255); }
	static Colour greenVogue() { return Colour(3, 43, 82, 255); }
	static Colour greenWaterloo() { return Colour(16, 20, 5, 255); }
	static Colour greenWhite() { return Colour(232, 235, 224, 255); }
	static Colour greenstone() { return Colour(0, 62, 64, 255); }
	static Colour grenadier() { return Colour(213, 70, 0, 255); }
	static Colour greyChateau() { return Colour(162, 170, 179, 255); }
	static Colour greyGreen() { return Colour(69, 73, 54, 255); }
	static Colour greyNickel() { return Colour(195, 195, 189, 255); }
	static Colour greyNurse() { return Colour(231, 236, 230, 255); }
	static Colour greyOlive() { return Colour(169, 164, 145, 255); }
	static Colour greySuit() { return Colour(193, 190, 205, 255); }
	static Colour guardsmanRed() { return Colour(186, 1, 1, 255); }
	static Colour gulfBlue() { return Colour(5, 22, 87, 255); }
	static Colour gulfStream() { return Colour(128, 179, 174, 255); }
	static Colour gullGrey() { return Colour(157, 172, 183, 255); }
	static Colour gumLeaf() { return Colour(182, 211, 191, 255); }
	static Colour gumbo() { return Colour(124, 161, 166, 255); }
	static Colour gunPowder() { return Colour(65, 66, 87, 255); }
	static Colour gunmetal() { return Colour(2, 13, 21, 255); }
	static Colour gunsmoke() { return Colour(130, 134, 133, 255); }
	static Colour gurkha() { return Colour(154, 149, 119, 255); }
	static Colour hacienda() { return Colour(152, 129, 27, 255); }
	static Colour hairyHeath() { return Colour(107, 42, 20, 255); }
	static Colour haiti() { return Colour(27, 16, 53, 255); }
	static Colour halfandHalf() { return Colour(255, 254, 225, 255); }
	static Colour halfBaked() { return Colour(133, 196, 204, 255); }
	static Colour halfColonialWhite() { return Colour(253, 246, 211, 255); }
	static Colour halfDutchWhite() { return Colour(254, 247, 222, 255); }
	static Colour halfPearlLusta() { return Colour(255, 252, 234, 255); }
	static Colour halfSpanishWhite() { return Colour(254, 244, 219, 255); }
	static Colour hampton() { return Colour(229, 216, 175, 255); }
	static Colour harp() { return Colour(230, 242, 234, 255); }
	static Colour harvestGold() { return Colour(224, 185, 116, 255); }
	static Colour havana() { return Colour(52, 21, 21, 255); }
	static Colour havelockBlue() { return Colour(85, 144, 217, 255); }
	static Colour hawaiianTan() { return Colour(157, 86, 22, 255); }
	static Colour hawkesBlue() { return Colour(212, 226, 252, 255); }
	static Colour heath() { return Colour(84, 16, 18, 255); }
	static Colour heather() { return Colour(183, 195, 208, 255); }
	static Colour heatheredGrey() { return Colour(182, 176, 149, 255); }
	static Colour heavyMetal() { return Colour(43, 50, 40, 255); }
	static Colour hemlock() { return Colour(94, 93, 59, 255); }
	static Colour hemp() { return Colour(144, 120, 116, 255); }
	static Colour hibiscus() { return Colour(182, 49, 108, 255); }
	static Colour highball() { return Colour(144, 141, 57, 255); }
	static Colour highland() { return Colour(111, 142, 99, 255); }
	static Colour hillary() { return Colour(172, 165, 134, 255); }
	static Colour himalaya() { return Colour(106, 93, 27, 255); }
	static Colour hintofGreen() { return Colour(230, 255, 233, 255); }
	static Colour hintofGrey() { return Colour(252, 255, 249, 255); }
	static Colour hintofRed() { return Colour(249, 249, 249, 255); }
	static Colour hintofYellow() { return Colour(250, 253, 228, 255); }
	static Colour hippieBlue() { return Colour(88, 154, 175, 255); }
	static Colour hippieGreen() { return Colour(83, 130, 75, 255); }
	static Colour hippiePink() { return Colour(174, 69, 96, 255); }
	static Colour hitGrey() { return Colour(161, 173, 181, 255); }
	static Colour hitPink() { return Colour(255, 171, 129, 255); }
	static Colour hokeyPokey() { return Colour(200, 165, 40, 255); }
	static Colour hoki() { return Colour(101, 134, 159, 255); }
	static Colour holly() { return Colour(1, 29, 19, 255); }
	static Colour honeyFlower() { return Colour(79, 28, 112, 255); }
	static Colour honeysuckle() { return Colour(237, 252, 132, 255); }
	static Colour hopbush() { return Colour(208, 109, 161, 255); }
	static Colour horizon() { return Colour(90, 135, 160, 255); }
	static Colour horsesNeck() { return Colour(96, 73, 19, 255); }
	static Colour hotChile() { return Colour(139, 7, 35, 255); }
	static Colour hotCurry() { return Colour(136, 98, 33, 255); }
	static Colour hotPurple() { return Colour(72, 6, 86, 255); }
	static Colour hotToddy() { return Colour(179, 128, 7, 255); }
	static Colour hummingBird() { return Colour(207, 249, 243, 255); }
	static Colour hunterGreen() { return Colour(22, 29, 16, 255); }
	static Colour hurricane() { return Colour(135, 124, 123, 255); }
	static Colour husk() { return Colour(183, 164, 88, 255); }
	static Colour iceCold() { return Colour(177, 244, 231, 255); }
	static Colour iceberg() { return Colour(218, 244, 240, 255); }
	static Colour illusion() { return Colour(246, 164, 201, 255); }
	static Colour indianTan() { return Colour(77, 30, 1, 255); }
	static Colour indochine() { return Colour(194, 107, 3, 255); }
	static Colour irishCoffee() { return Colour(95, 61, 38, 255); }
	static Colour iroko() { return Colour(67, 49, 32, 255); }
	static Colour iron() { return Colour(212, 215, 217, 255); }
	static Colour ironbark() { return Colour(65, 31, 16, 255); }
	static Colour ironsideGrey() { return Colour(103, 102, 98, 255); }
	static Colour ironstone() { return Colour(134, 72, 60, 255); }
	static Colour islandSpice() { return Colour(255, 252, 238, 255); }
	static Colour jacaranda() { return Colour(46, 3, 41, 255); }
	static Colour jacarta() { return Colour(58, 42, 106, 255); }
	static Colour jackoBean() { return Colour(46, 25, 5, 255); }
	static Colour jacksonsPurple() { return Colour(32, 32, 141, 255); }
	static Colour jade() { return Colour(66, 121, 119, 255); }
	static Colour jaffa() { return Colour(239, 134, 63, 255); }
	static Colour jaggedIce() { return Colour(194, 232, 229, 255); }
	static Colour jagger() { return Colour(53, 14, 87, 255); }
	static Colour jaguar() { return Colour(8, 1, 16, 255); }
	static Colour jambalaya() { return Colour(91, 48, 19, 255); }
	static Colour janna() { return Colour(244, 235, 211, 255); }
	static Colour japaneseLaurel() { return Colour(10, 105, 6, 255); }
	static Colour japaneseMaple() { return Colour(120, 1, 9, 255); }
	static Colour japonica() { return Colour(216, 124, 99, 255); }
	static Colour jarrah() { return Colour(52, 21, 21, 255); }
	static Colour java() { return Colour(31, 194, 194, 255); }
	static Colour jazz() { return Colour(120, 1, 9, 255); }
	static Colour jellyBean() { return Colour(41, 123, 154, 255); }
	static Colour jetStream() { return Colour(181, 210, 206, 255); }
	static Colour jewel() { return Colour(18, 107, 64, 255); }
	static Colour joanna() { return Colour(245, 243, 229, 255); }
	static Colour jon() { return Colour(59, 31, 31, 255); }
	static Colour jonquil() { return Colour(238, 255, 154, 255); }
	static Colour jordyBlue() { return Colour(138, 185, 241, 255); }
	static Colour judgeGrey() { return Colour(84, 67, 51, 255); }
	static Colour jumbo() { return Colour(124, 123, 130, 255); }
	static Colour jungleGreen() { return Colour(40, 30, 21, 255); }
	static Colour jungleMist() { return Colour(180, 207, 211, 255); }
	static Colour juniper() { return Colour(109, 146, 146, 255); }
	static Colour justRight() { return Colour(236, 205, 185, 255); }
	static Colour kabul() { return Colour(94, 72, 62, 255); }
	static Colour kaitokeGreen() { return Colour(0, 70, 32, 255); }
	static Colour kangaroo() { return Colour(198, 200, 189, 255); }
	static Colour karaka() { return Colour(30, 22, 9, 255); }
	static Colour karry() { return Colour(255, 234, 212, 255); }
	static Colour kashmirBlue() { return Colour(80, 112, 150, 255); }
	static Colour kelp() { return Colour(69, 73, 54, 255); }
	static Colour kenyanCopper() { return Colour(124, 28, 5, 255); }
	static Colour keppel() { return Colour(58, 176, 158, 255); }
	static Colour kidnapper() { return Colour(225, 234, 212, 255); }
	static Colour kilamanjaro() { return Colour(36, 12, 2, 255); }
	static Colour killarney() { return Colour(58, 106, 71, 255); }
	static Colour kimberly() { return Colour(115, 108, 159, 255); }
	static Colour kingfisherDaisy() { return Colour(62, 4, 128, 255); }
	static Colour kobi() { return Colour(231, 159, 196, 255); }
	static Colour kokoda() { return Colour(110, 109, 87, 255); }
	static Colour korma() { return Colour(143, 75, 14, 255); }
	static Colour koromiko() { return Colour(255, 189, 95, 255); }
	static Colour kournikova() { return Colour(255, 231, 114, 255); }
	static Colour kumera() { return Colour(136, 98, 33, 255); }
	static Colour laPalma() { return Colour(54, 135, 22, 255); }
	static Colour laRioja() { return Colour(179, 193, 16, 255); }
	static Colour lasPalmas() { return Colour(198, 230, 16, 255); }
	static Colour laser() { return Colour(200, 181, 104, 255); }
	static Colour laurel() { return Colour(116, 147, 120, 255); }
	static Colour lavender() { return Colour(168, 153, 230, 255); }
	static Colour leather() { return Colour(150, 112, 89, 255); }
	static Colour lemon() { return Colour(244, 216, 28, 255); }
	static Colour lemonGinger() { return Colour(172, 158, 34, 255); }
	static Colour lemonGrass() { return Colour(155, 158, 143, 255); }
	static Colour licorice() { return Colour(9, 34, 86, 255); }
	static Colour lightningYellow() { return Colour(252, 192, 30, 255); }
	static Colour lilacBush() { return Colour(152, 116, 211, 255); }
	static Colour lily() { return Colour(200, 170, 191, 255); }
	static Colour lilyWhite() { return Colour(231, 248, 255, 255); }
	static Colour lima() { return Colour(118, 189, 23, 255); }
	static Colour lime() { return Colour(191, 201, 33, 255); }
	static Colour limeade() { return Colour(111, 157, 2, 255); }
	static Colour limedAsh() { return Colour(116, 125, 99, 255); }
	static Colour limedGum() { return Colour(66, 57, 33, 255); }
	static Colour limedOak() { return Colour(172, 138, 86, 255); }
	static Colour limedSpruce() { return Colour(57, 72, 81, 255); }
	static Colour limerick() { return Colour(157, 194, 9, 255); }
	static Colour linen() { return Colour(230, 228, 212, 255); }
	static Colour linkWater() { return Colour(217, 228, 245, 255); }
	static Colour lipstick() { return Colour(171, 5, 99, 255); }
	static Colour lisbonBrown() { return Colour(66, 57, 33, 255); }
	static Colour lividBrown() { return Colour(77, 40, 46, 255); }
	static Colour loafer() { return Colour(238, 244, 222, 255); }
	static Colour loblolly() { return Colour(189, 201, 206, 255); }
	static Colour lochinvar() { return Colour(44, 140, 132, 255); }
	static Colour lochmara() { return Colour(0, 126, 199, 255); }
	static Colour locust() { return Colour(168, 175, 142, 255); }
	static Colour logCabin() { return Colour(36, 42, 29, 255); }
	static Colour logan() { return Colour(170, 169, 205, 255); }
	static Colour lola() { return Colour(223, 207, 219, 255); }
	static Colour londonHue() { return Colour(190, 166, 195, 255); }
	static Colour lonestar() { return Colour(109, 1, 1, 255); }
	static Colour lotus() { return Colour(134, 60, 60, 255); }
	static Colour loulou() { return Colour(70, 11, 65, 255); }
	static Colour lucky() { return Colour(175, 159, 28, 255); }
	static Colour luckyPoint() { return Colour(26, 26, 104, 255); }
	static Colour lunarGreen() { return Colour(60, 73, 58, 255); }
	static Colour lusty() { return Colour(153, 27, 7, 255); }
	static Colour luxorGold() { return Colour(167, 136, 44, 255); }
	static Colour lynch() { return Colour(105, 126, 154, 255); }
	static Colour mabel() { return Colour(217, 247, 255, 255); }
	static Colour madang() { return Colour(183, 240, 190, 255); }
	static Colour madison() { return Colour(9, 37, 93, 255); }
	static Colour madras() { return Colour(63, 48, 2, 255); }
	static Colour magnolia() { return Colour(248, 244, 255, 255); }
	static Colour mahogany() { return Colour(78, 6, 6, 255); }
	static Colour maiTai() { return Colour(176, 102, 8, 255); }
	static Colour maire() { return Colour(19, 10, 6, 255); }
	static Colour maize() { return Colour(245, 213, 160, 255); }
	static Colour makara() { return Colour(137, 125, 109, 255); }
	static Colour mako() { return Colour(68, 73, 84, 255); }
	static Colour malachiteGreen() { return Colour(136, 141, 101, 255); }
	static Colour malibu() { return Colour(125, 200, 247, 255); }
	static Colour mallard() { return Colour(35, 52, 24, 255); }
	static Colour malta() { return Colour(189, 178, 161, 255); }
	static Colour mamba() { return Colour(142, 129, 144, 255); }
	static Colour mandalay() { return Colour(173, 120, 27, 255); }
	static Colour mandy() { return Colour(226, 84, 101, 255); }
	static Colour mandysPink() { return Colour(242, 195, 178, 255); }
	static Colour manhattan() { return Colour(245, 201, 153, 255); }
	static Colour mantis() { return Colour(116, 195, 101, 255); }
	static Colour mantle() { return Colour(139, 156, 144, 255); }
	static Colour manz() { return Colour(238, 239, 120, 255); }
	static Colour mardiGras() { return Colour(53, 0, 54, 255); }
	static Colour marigold() { return Colour(185, 141, 40, 255); }
	static Colour mariner() { return Colour(40, 106, 205, 255); }
	static Colour marlin() { return Colour(42, 20, 14, 255); }
	static Colour maroon() { return Colour(66, 3, 3, 255); }
	static Colour marshland() { return Colour(11, 15, 8, 255); }
	static Colour martini() { return Colour(175, 160, 158, 255); }
	static Colour martinique() { return Colour(54, 48, 80, 255); }
	static Colour marzipan() { return Colour(248, 219, 157, 255); }
	static Colour masala() { return Colour(64, 59, 56, 255); }
	static Colour mash() { return Colour(64, 41, 29, 255); }
	static Colour matisse() { return Colour(27, 101, 157, 255); }
	static Colour matrix() { return Colour(176, 93, 84, 255); }
	static Colour matterhorn() { return Colour(78, 59, 65, 255); }
	static Colour maverick() { return Colour(216, 194, 213, 255); }
	static Colour mckenzie() { return Colour(175, 135, 81, 255); }
	static Colour melanie() { return Colour(228, 194, 213, 255); }
	static Colour melanzane() { return Colour(48, 5, 41, 255); }
	static Colour melrose() { return Colour(199, 193, 255, 255); }
	static Colour meranti() { return Colour(93, 30, 15, 255); }
	static Colour mercury() { return Colour(229, 229, 229, 255); }
	static Colour merino() { return Colour(246, 240, 230, 255); }
	static Colour merlin() { return Colour(65, 60, 55, 255); }
	static Colour merlot() { return Colour(131, 25, 35, 255); }
	static Colour metallicBronze() { return Colour(73, 55, 27, 255); }
	static Colour metallicCopper() { return Colour(113, 41, 29, 255); }
	static Colour meteor() { return Colour(208, 125, 18, 255); }
	static Colour meteorite() { return Colour(60, 31, 118, 255); }
	static Colour mexicanRed() { return Colour(167, 37, 37, 255); }
	static Colour midGrey() { return Colour(95, 95, 110, 255); }
	static Colour midnight() { return Colour(1, 22, 53, 255); }
	static Colour midnightExpress() { return Colour(0, 7, 65, 255); }
	static Colour midnightMoss() { return Colour(4, 16, 4, 255); }
	static Colour mikado() { return Colour(45, 37, 16, 255); }
	static Colour milan() { return Colour(250, 255, 164, 255); }
	static Colour milanoRed() { return Colour(184, 17, 4, 255); }
	static Colour milkPunch() { return Colour(255, 246, 212, 255); }
	static Colour milkWhite() { return Colour(246, 240, 230, 255); }
	static Colour millbrook() { return Colour(89, 68, 51, 255); }
	static Colour mimosa() { return Colour(248, 253, 211, 255); }
	static Colour mindaro() { return Colour(227, 249, 136, 255); }
	static Colour mineShaft() { return Colour(50, 50, 50, 255); }
	static Colour mineralGreen() { return Colour(63, 93, 83, 255); }
	static Colour ming() { return Colour(54, 116, 125, 255); }
	static Colour minsk() { return Colour(63, 48, 127, 255); }
	static Colour mintJulep() { return Colour(241, 238, 193, 255); }
	static Colour mintTulip() { return Colour(196, 244, 235, 255); }
	static Colour mirage() { return Colour(22, 25, 40, 255); }
	static Colour mischka() { return Colour(209, 210, 221, 255); }
	static Colour mistGrey() { return Colour(196, 196, 188, 255); }
	static Colour mobster() { return Colour(127, 117, 137, 255); }
	static Colour moccaccino() { return Colour(110, 29, 20, 255); }
	static Colour mocha() { return Colour(120, 45, 25, 255); }
	static Colour mojo() { return Colour(192, 71, 55, 255); }
	static Colour monaLisa() { return Colour(255, 161, 148, 255); }
	static Colour monarch() { return Colour(139, 7, 35, 255); }
	static Colour mondo() { return Colour(74, 60, 48, 255); }
	static Colour mongoose() { return Colour(181, 162, 127, 255); }
	static Colour monsoon() { return Colour(138, 131, 137, 255); }
	static Colour montana() { return Colour(41, 30, 48, 255); }
	static Colour monteCarlo() { return Colour(131, 208, 198, 255); }
	static Colour monza() { return Colour(199, 3, 30, 255); }
	static Colour moodyBlue() { return Colour(127, 118, 211, 255); }
	static Colour moonGlow() { return Colour(252, 254, 218, 255); }
	static Colour moonMist() { return Colour(220, 221, 204, 255); }
	static Colour moonRaker() { return Colour(214, 206, 246, 255); }
	static Colour moonYellow() { return Colour(252, 217, 23, 255); }
	static Colour morningGlory() { return Colour(158, 222, 224, 255); }
	static Colour moroccoBrown() { return Colour(68, 29, 0, 255); }
	static Colour mortar() { return Colour(80, 67, 81, 255); }
	static Colour mosaic() { return Colour(18, 52, 71, 255); }
	static Colour mosque() { return Colour(3, 106, 110, 255); }
	static Colour mountainMist() { return Colour(149, 147, 150, 255); }
	static Colour muddyWaters() { return Colour(183, 142, 92, 255); }
	static Colour muesli() { return Colour(170, 139, 91, 255); }
	static Colour mulberry() { return Colour(92, 5, 54, 255); }
	static Colour muleFawn() { return Colour(140, 71, 47, 255); }
	static Colour mulledWine() { return Colour(78, 69, 98, 255); }
	static Colour mustard() { return Colour(116, 100, 13, 255); }
	static Colour myPink() { return Colour(214, 145, 136, 255); }
	static Colour mySin() { return Colour(255, 179, 31, 255); }
	static Colour mystic() { return Colour(226, 235, 237, 255); }
	static Colour nandor() { return Colour(75, 93, 82, 255); }
	static Colour napa() { return Colour(172, 164, 148, 255); }
	static Colour narvik() { return Colour(237, 249, 241, 255); }
	static Colour natural() { return Colour(134, 86, 10, 255); }
	static Colour nebula() { return Colour(203, 219, 214, 255); }
	static Colour negroni() { return Colour(255, 226, 197, 255); }
	static Colour nepal() { return Colour(142, 171, 193, 255); }
	static Colour neptune() { return Colour(124, 183, 187, 255); }
	static Colour nero() { return Colour(20, 6, 0, 255); }
	static Colour neutralGreen() { return Colour(172, 165, 134, 255); }
	static Colour nevada() { return Colour(100, 110, 117, 255); }
	static Colour newAmber() { return Colour(123, 56, 1, 255); }
	static Colour newOrleans() { return Colour(243, 214, 157, 255); }
	static Colour newYorkPink() { return Colour(215, 131, 127, 255); }
	static Colour niagara() { return Colour(6, 161, 137, 255); }
	static Colour nightRider() { return Colour(31, 18, 15, 255); }
	static Colour nightShadz() { return Colour(170, 55, 90, 255); }
	static Colour nightclub() { return Colour(102, 0, 69, 255); }
	static Colour nileBlue() { return Colour(25, 55, 81, 255); }
	static Colour nobel() { return Colour(183, 177, 177, 255); }
	static Colour nomad() { return Colour(186, 177, 162, 255); }
	static Colour nordic() { return Colour(1, 39, 49, 255); }
	static Colour norway() { return Colour(168, 189, 159, 255); }
	static Colour nugget() { return Colour(197, 153, 34, 255); }
	static Colour nutmeg() { return Colour(129, 66, 44, 255); }
	static Colour nutmegWoodFinish() { return Colour(104, 54, 0, 255); }
	static Colour oasis() { return Colour(254, 239, 206, 255); }
	static Colour observatory() { return Colour(2, 134, 111, 255); }
	static Colour oceanGreen() { return Colour(65, 170, 120, 255); }
	static Colour offGreen() { return Colour(230, 248, 243, 255); }
	static Colour offYellow() { return Colour(254, 249, 227, 255); }
	static Colour oil() { return Colour(40, 30, 21, 255); }
	static Colour oiledCedar() { return Colour(124, 28, 5, 255); }
	static Colour oldBrick() { return Colour(144, 30, 30, 255); }
	static Colour oldCopper() { return Colour(114, 74, 47, 255); }
	static Colour oliveGreen() { return Colour(36, 46, 22, 255); }
	static Colour oliveHaze() { return Colour(139, 132, 112, 255); }
	static Colour olivetone() { return Colour(113, 110, 16, 255); }
	static Colour onahau() { return Colour(205, 244, 255, 255); }
	static Colour onion() { return Colour(47, 39, 14, 255); }
	static Colour opal() { return Colour(169, 198, 194, 255); }
	static Colour opium() { return Colour(142, 111, 112, 255); }
	static Colour oracle() { return Colour(55, 116, 117, 255); }
	static Colour orangeRoughy() { return Colour(196, 87, 25, 255); }
	static Colour orangeWhite() { return Colour(254, 252, 237, 255); }
	static Colour orchidWhite() { return Colour(255, 253, 243, 255); }
	static Colour oregon() { return Colour(155, 71, 3, 255); }
	static Colour orient() { return Colour(1, 94, 133, 255); }
	static Colour orientalPink() { return Colour(198, 145, 145, 255); }
	static Colour orinoco() { return Colour(243, 251, 212, 255); }
	static Colour osloGrey() { return Colour(135, 141, 145, 255); }
	static Colour ottoman() { return Colour(233, 248, 237, 255); }
	static Colour outerSpace() { return Colour(5, 16, 64, 255); }
	static Colour oxfordBlue() { return Colour(56, 69, 85, 255); }
	static Colour oxley() { return Colour(119, 158, 134, 255); }
	static Colour oysterBay() { return Colour(218, 250, 255, 255); }
	static Colour oysterPink() { return Colour(233, 206, 205, 255); }
	static Colour paarl() { return Colour(166, 85, 41, 255); }
	static Colour pablo() { return Colour(119, 111, 97, 255); }
	static Colour pacifika() { return Colour(119, 129, 32, 255); }
	static Colour paco() { return Colour(65, 31, 16, 255); }
	static Colour padua() { return Colour(173, 230, 196, 255); }
	static Colour paleLeaf() { return Colour(192, 211, 185, 255); }
	static Colour paleOyster() { return Colour(152, 141, 119, 255); }
	static Colour palePrim() { return Colour(253, 254, 184, 255); }
	static Colour paleRose() { return Colour(255, 225, 242, 255); }
	static Colour paleSky() { return Colour(110, 119, 131, 255); }
	static Colour paleSlate() { return Colour(195, 191, 193, 255); }
	static Colour palmGreen() { return Colour(9, 35, 15, 255); }
	static Colour palmLeaf() { return Colour(25, 51, 14, 255); }
	static Colour pampas() { return Colour(244, 242, 238, 255); }
	static Colour panache() { return Colour(234, 246, 238, 255); }
	static Colour pancho() { return Colour(237, 205, 171, 255); }
	static Colour panda() { return Colour(66, 57, 33, 255); }
	static Colour paprika() { return Colour(141, 2, 38, 255); }
	static Colour paradiso() { return Colour(49, 125, 130, 255); }
	static Colour parchment() { return Colour(241, 233, 210, 255); }
	static Colour parisDaisy() { return Colour(255, 244, 110, 255); }
	static Colour parisM() { return Colour(38, 5, 106, 255); }
	static Colour parisWhite() { return Colour(202, 220, 212, 255); }
	static Colour parsley() { return Colour(19, 79, 25, 255); }
	static Colour patina() { return Colour(99, 154, 143, 255); }
	static Colour pattensBlue() { return Colour(222, 245, 255, 255); }
	static Colour paua() { return Colour(38, 3, 104, 255); }
	static Colour pavlova() { return Colour(215, 196, 152, 255); }
	static Colour peaSoup() { return Colour(207, 229, 210, 255); }
	static Colour peach() { return Colour(255, 240, 219, 255); }
	static Colour peachSchnapps() { return Colour(255, 220, 214, 255); }
	static Colour peanut() { return Colour(120, 47, 22, 255); }
	static Colour pearlBush() { return Colour(232, 224, 213, 255); }
	static Colour pearlLusta() { return Colour(252, 244, 220, 255); }
	static Colour peat() { return Colour(113, 107, 86, 255); }
	static Colour pelorous() { return Colour(62, 171, 191, 255); }
	static Colour peppermint() { return Colour(227, 245, 225, 255); }
	static Colour perano() { return Colour(169, 190, 242, 255); }
	static Colour perfume() { return Colour(208, 190, 248, 255); }
	static Colour periglacialBlue() { return Colour(225, 230, 214, 255); }
	static Colour persianPlum() { return Colour(112, 28, 28, 255); }
	static Colour persianRed() { return Colour(82, 12, 23, 255); }
	static Colour persimmon() { return Colour(255, 107, 83, 255); }
	static Colour peruTan() { return Colour(127, 58, 2, 255); }
	static Colour pesto() { return Colour(124, 118, 49, 255); }
	static Colour petiteOrchid() { return Colour(219, 150, 144, 255); }
	static Colour pewter() { return Colour(150, 168, 161, 255); }
	static Colour pharlap() { return Colour(163, 128, 123, 255); }
	static Colour picasso() { return Colour(255, 243, 157, 255); }
	static Colour pickledAspen() { return Colour(63, 76, 58, 255); }
	static Colour pickledBean() { return Colour(110, 72, 38, 255); }
	static Colour pickledBluewood() { return Colour(49, 68, 89, 255); }
	static Colour pictonBlue() { return Colour(69, 177, 232, 255); }
	static Colour pigeonPost() { return Colour(175, 189, 217, 255); }
	static Colour pineCone() { return Colour(109, 94, 84, 255); }
	static Colour pineGlade() { return Colour(199, 205, 144, 255); }
	static Colour pineTree() { return Colour(23, 31, 4, 255); }
	static Colour pinkFlare() { return Colour(225, 192, 200, 255); }
	static Colour pinkLace() { return Colour(255, 221, 244, 255); }
	static Colour pinkLady() { return Colour(255, 241, 216, 255); }
	static Colour pinkSwan() { return Colour(190, 181, 183, 255); }
	static Colour piper() { return Colour(201, 99, 35, 255); }
	static Colour pipi() { return Colour(254, 244, 204, 255); }
	static Colour pippin() { return Colour(255, 225, 223, 255); }
	static Colour pirateGold() { return Colour(186, 127, 3, 255); }
	static Colour pistachio() { return Colour(157, 194, 9, 255); }
	static Colour pixieGreen() { return Colour(192, 216, 182, 255); }
	static Colour pizazz() { return Colour(255, 144, 0, 255); }
	static Colour pizza() { return Colour(201, 148, 21, 255); }
	static Colour plantation() { return Colour(39, 80, 75, 255); }
	static Colour planter() { return Colour(97, 93, 48, 255); }
	static Colour plum() { return Colour(65, 0, 86, 255); }
	static Colour pohutukawa() { return Colour(143, 2, 28, 255); }
	static Colour polar() { return Colour(229, 249, 246, 255); }
	static Colour poloBlue() { return Colour(141, 168, 204, 255); }
	static Colour pompadour() { return Colour(102, 0, 69, 255); }
	static Colour porcelain() { return Colour(239, 242, 243, 255); }
	static Colour porsche() { return Colour(234, 174, 105, 255); }
	static Colour portGore() { return Colour(37, 31, 79, 255); }
	static Colour portafino() { return Colour(255, 255, 180, 255); }
	static Colour portage() { return Colour(139, 159, 238, 255); }
	static Colour portica() { return Colour(249, 230, 99, 255); }
	static Colour potPourri() { return Colour(245, 231, 226, 255); }
	static Colour pottersClay() { return Colour(140, 87, 56, 255); }
	static Colour powderBlue() { return Colour(188, 201, 194, 255); }
	static Colour prairieSand() { return Colour(154, 56, 32, 255); }
	static Colour prelude() { return Colour(208, 192, 229, 255); }
	static Colour prim() { return Colour(240, 226, 236, 255); }
	static Colour primrose() { return Colour(237, 234, 153, 255); }
	static Colour promenade() { return Colour(252, 255, 231, 255); }
	static Colour provincialPink() { return Colour(254, 245, 241, 255); }
	static Colour prussianBlue() { return Colour(0, 49, 83, 255); }
	static Colour pueblo() { return Colour(125, 44, 20, 255); }
	static Colour puertoRico() { return Colour(63, 193, 170, 255); }
	static Colour pumice() { return Colour(194, 202, 196, 255); }
	static Colour pumpkin() { return Colour(177, 97, 11, 255); }
	static Colour punch() { return Colour(220, 67, 51, 255); }
	static Colour punga() { return Colour(77, 61, 20, 255); }
	static Colour putty() { return Colour(231, 205, 140, 255); }
	static Colour quarterPearlLusta() { return Colour(255, 253, 244, 255); }
	static Colour quarterSpanishWhite() { return Colour(247, 242, 225, 255); }
	static Colour quicksand() { return Colour(189, 151, 142, 255); }
	static Colour quillGrey() { return Colour(214, 214, 209, 255); }
	static Colour quincy() { return Colour(98, 63, 45, 255); }
	static Colour racingGreen() { return Colour(12, 25, 17, 255); }
	static Colour raffia() { return Colour(234, 218, 184, 255); }
	static Colour rainForest() { return Colour(119, 129, 32, 255); }
	static Colour raincloud() { return Colour(123, 124, 148, 255); }
	static Colour rainee() { return Colour(185, 200, 172, 255); }
	static Colour rajah() { return Colour(247, 182, 104, 255); }
	static Colour rangitoto() { return Colour(46, 50, 34, 255); }
	static Colour rangoonGreen() { return Colour(28, 30, 19, 255); }
	static Colour raven() { return Colour(114, 123, 137, 255); }
	static Colour rebel() { return Colour(60, 18, 6, 255); }
	static Colour redBeech() { return Colour(123, 56, 1, 255); }
	static Colour redBerry() { return Colour(142, 0, 0, 255); }
	static Colour redDamask() { return Colour(218, 106, 65, 255); }
	static Colour redDevil() { return Colour(134, 1, 17, 255); }
	static Colour redOxide() { return Colour(110, 9, 2, 255); }
	static Colour redRobin() { return Colour(128, 52, 31, 255); }
	static Colour redStage() { return Colour(208, 95, 4, 255); }
	static Colour redwood() { return Colour(93, 30, 15, 255); }
	static Colour reef() { return Colour(201, 255, 162, 255); }
	static Colour reefGold() { return Colour(159, 130, 28, 255); }
	static Colour regalBlue() { return Colour(1, 63, 106, 255); }
	static Colour regentGrey() { return Colour(134, 148, 159, 255); }
	static Colour regentStBlue() { return Colour(170, 214, 230, 255); }
	static Colour remy() { return Colour(254, 235, 243, 255); }
	static Colour renoSand() { return Colour(168, 101, 21, 255); }
	static Colour resolutionBlue() { return Colour(0, 35, 135, 255); }
	static Colour revolver() { return Colour(44, 22, 50, 255); }
	static Colour rhino() { return Colour(46, 63, 98, 255); }
	static Colour ribbon() { return Colour(102, 0, 69, 255); }
	static Colour riceCake() { return Colour(255, 254, 240, 255); }
	static Colour riceFlower() { return Colour(238, 255, 226, 255); }
	static Colour richGold() { return Colour(168, 83, 7, 255); }
	static Colour rioGrande() { return Colour(187, 208, 9, 255); }
	static Colour riptide() { return Colour(139, 230, 216, 255); }
	static Colour riverBed() { return Colour(67, 76, 89, 255); }
	static Colour robRoy() { return Colour(234, 198, 116, 255); }
	static Colour robinsEggBlue() { return Colour(189, 200, 179, 255); }
	static Colour rock() { return Colour(77, 56, 51, 255); }
	static Colour rockBlue() { return Colour(158, 177, 205, 255); }
	static Colour rockSalt() { return Colour(255, 255, 255, 255); }
	static Colour rockSpray() { return Colour(186, 69, 12, 255); }
	static Colour rodeoDust() { return Colour(201, 178, 155, 255); }
	static Colour rollingStone() { return Colour(116, 125, 131, 255); }
	static Colour roman() { return Colour(222, 99, 96, 255); }
	static Colour romanCoffee() { return Colour(121, 93, 76, 255); }
	static Colour romance() { return Colour(255, 254, 253, 255); }
	static Colour romantic() { return Colour(255, 210, 183, 255); }
	static Colour ronchi() { return Colour(236, 197, 78, 255); }
	static Colour roofTerracotta() { return Colour(166, 47, 32, 255); }
	static Colour rope() { return Colour(142, 77, 30, 255); }
	static Colour rose() { return Colour(231, 188, 180, 255); }
	static Colour roseBud() { return Colour(251, 178, 163, 255); }
	static Colour roseBudCherry() { return Colour(128, 11, 71, 255); }
	static Colour roseofSharon() { return Colour(191, 85, 0, 255); }
	static Colour roseWhite() { return Colour(255, 246, 245, 255); }
	static Colour rosewood() { return Colour(101, 0, 11, 255); }
	static Colour roti() { return Colour(198, 168, 75, 255); }
	static Colour rouge() { return Colour(162, 59, 108, 255); }
	static Colour royalHeath() { return Colour(171, 52, 114, 255); }
	static Colour rum() { return Colour(121, 105, 137, 255); }
	static Colour rumSwizzle() { return Colour(249, 248, 228, 255); }
	static Colour russett() { return Colour(117, 90, 87, 255); }
	static Colour rusticRed() { return Colour(72, 4, 4, 255); }
	static Colour rustyNail() { return Colour(134, 86, 10, 255); }
	static Colour saddle() { return Colour(76, 48, 36, 255); }
	static Colour saddleBrown() { return Colour(88, 52, 1, 255); }
	static Colour saffron() { return Colour(249, 191, 88, 255); }
	static Colour sage() { return Colour(158, 165, 135, 255); }
	static Colour sahara() { return Colour(183, 162, 20, 255); }
	static Colour sail() { return Colour(184, 224, 249, 255); }
	static Colour salem() { return Colour(9, 127, 75, 255); }
	static Colour salomie() { return Colour(254, 219, 141, 255); }
	static Colour saltBox() { return Colour(104, 94, 110, 255); }
	static Colour saltpan() { return Colour(241, 247, 242, 255); }
	static Colour sambuca() { return Colour(58, 32, 16, 255); }
	static Colour sanFelix() { return Colour(11, 98, 7, 255); }
	static Colour sanJuan() { return Colour(48, 75, 106, 255); }
	static Colour sanMarino() { return Colour(69, 108, 172, 255); }
	static Colour sandDune() { return Colour(130, 111, 101, 255); }
	static Colour sandal() { return Colour(170, 141, 111, 255); }
	static Colour sandrift() { return Colour(171, 145, 122, 255); }
	static Colour sandstone() { return Colour(121, 109, 98, 255); }
	static Colour sandwisp() { return Colour(245, 231, 162, 255); }
	static Colour sandyBeach() { return Colour(255, 234, 200, 255); }
	static Colour sangria() { return Colour(146, 0, 10, 255); }
	static Colour sanguineBrown() { return Colour(141, 61, 56, 255); }
	static Colour santaFe() { return Colour(177, 109, 82, 255); }
	static Colour santasGrey() { return Colour(159, 160, 177, 255); }
	static Colour sapling() { return Colour(222, 212, 164, 255); }
	static Colour sapphire() { return Colour(47, 81, 158, 255); }
	static Colour saratoga() { return Colour(85, 91, 16, 255); }
	static Colour sauvignon() { return Colour(255, 245, 243, 255); }
	static Colour sazerac() { return Colour(255, 244, 224, 255); }
	static Colour scampi() { return Colour(103, 95, 166, 255); }
	static Colour scandal() { return Colour(207, 250, 244, 255); }
	static Colour scarletGum() { return Colour(67, 21, 96, 255); }
	static Colour scarlett() { return Colour(149, 0, 21, 255); }
	static Colour scarpaFlow() { return Colour(88, 85, 98, 255); }
	static Colour schist() { return Colour(169, 180, 151, 255); }
	static Colour schooner() { return Colour(139, 132, 126, 255); }
	static Colour scooter() { return Colour(46, 191, 212, 255); }
	static Colour scorpion() { return Colour(105, 95, 98, 255); }
	static Colour scotchMist() { return Colour(255, 251, 220, 255); }
	static Colour scrub() { return Colour(46, 50, 34, 255); }
	static Colour seaBuckthorn() { return Colour(251, 161, 41, 255); }
	static Colour seaFog() { return Colour(252, 255, 249, 255); }
	static Colour seaGreen() { return Colour(9, 88, 89, 255); }
	static Colour seaMist() { return Colour(197, 219, 202, 255); }
	static Colour seaNymph() { return Colour(120, 163, 156, 255); }
	static Colour seaPink() { return Colour(237, 152, 158, 255); }
	static Colour seagull() { return Colour(128, 204, 234, 255); }
	static Colour seance() { return Colour(115, 30, 143, 255); }
	static Colour seashell() { return Colour(241, 241, 241, 255); }
	static Colour seaweed() { return Colour(27, 47, 17, 255); }
	static Colour selago() { return Colour(240, 238, 253, 255); }
	static Colour sepia() { return Colour(43, 2, 2, 255); }
	static Colour serenade() { return Colour(255, 244, 232, 255); }
	static Colour shadowGreen() { return Colour(154, 194, 184, 255); }
	static Colour shadyLady() { return Colour(170, 165, 169, 255); }
	static Colour shakespeare() { return Colour(78, 171, 209, 255); }
	static Colour shalimar() { return Colour(251, 255, 186, 255); }
	static Colour shark() { return Colour(37, 39, 44, 255); }
	static Colour sherpaBlue() { return Colour(0, 73, 80, 255); }
	static Colour sherwoodGreen() { return Colour(2, 64, 44, 255); }
	static Colour shilo() { return Colour(232, 185, 179, 255); }
	static Colour shingleFawn() { return Colour(107, 78, 49, 255); }
	static Colour shipCove() { return Colour(120, 139, 186, 255); }
	static Colour shipGrey() { return Colour(62, 58, 68, 255); }
	static Colour shiraz() { return Colour(178, 9, 49, 255); }
	static Colour shocking() { return Colour(226, 146, 192, 255); }
	static Colour shuttleGrey() { return Colour(95, 102, 114, 255); }
	static Colour siam() { return Colour(100, 106, 84, 255); }
	static Colour sidecar() { return Colour(243, 231, 187, 255); }
	static Colour silk() { return Colour(189, 177, 168, 255); }
	static Colour silverChalice() { return Colour(172, 172, 172, 255); }
	static Colour silverSand() { return Colour(191, 193, 194, 255); }
	static Colour silverTree() { return Colour(102, 181, 143, 255); }
	static Colour sinbad() { return Colour(159, 215, 211, 255); }
	static Colour siren() { return Colour(122, 1, 58, 255); }
	static Colour sirocco() { return Colour(113, 128, 128, 255); }
	static Colour sisal() { return Colour(211, 203, 186, 255); }
	static Colour skeptic() { return Colour(202, 230, 218, 255); }
	static Colour slugger() { return Colour(65, 32, 16, 255); }
	static Colour smaltBlue() { return Colour(81, 128, 143, 255); }
	static Colour smokeTree() { return Colour(218, 99, 4, 255); }
	static Colour smokeyAsh() { return Colour(65, 60, 55, 255); }
	static Colour smoky() { return Colour(96, 91, 115, 255); }
	static Colour snowDrift() { return Colour(247, 250, 247, 255); }
	static Colour snowFlurry() { return Colour(228, 255, 209, 255); }
	static Colour snowyMint() { return Colour(214, 255, 219, 255); }
	static Colour snuff() { return Colour(226, 216, 237, 255); }
	static Colour soapstone() { return Colour(255, 251, 249, 255); }
	static Colour softAmber() { return Colour(209, 198, 180, 255); }
	static Colour softPeach() { return Colour(245, 237, 239, 255); }
	static Colour solidPink() { return Colour(137, 56, 67, 255); }
	static Colour solitaire() { return Colour(254, 248, 226, 255); }
	static Colour solitude() { return Colour(234, 246, 255, 255); }
	static Colour sorbus() { return Colour(253, 124, 7, 255); }
	static Colour sorrellBrown() { return Colour(206, 185, 143, 255); }
	static Colour sourDough() { return Colour(209, 190, 168, 255); }
	static Colour soyaBean() { return Colour(106, 96, 81, 255); }
	static Colour spaceShuttle() { return Colour(67, 49, 32, 255); }
	static Colour spanishGreen() { return Colour(129, 152, 133, 255); }
	static Colour spanishWhite() { return Colour(244, 235, 211, 255); }
	static Colour spectra() { return Colour(47, 90, 87, 255); }
	static Colour spice() { return Colour(106, 68, 46, 255); }
	static Colour spicyMix() { return Colour(136, 83, 66, 255); }
	static Colour spicyPink() { return Colour(129, 110, 113, 255); }
	static Colour spindle() { return Colour(182, 209, 234, 255); }
	static Colour splash() { return Colour(255, 239, 193, 255); }
	static Colour spray() { return Colour(121, 222, 236, 255); }
	static Colour springGreen() { return Colour(87, 131, 99, 255); }
	static Colour springRain() { return Colour(172, 203, 177, 255); }
	static Colour springSun() { return Colour(246, 255, 220, 255); }
	static Colour springWood() { return Colour(248, 246, 241, 255); }
	static Colour sprout() { return Colour(193, 215, 176, 255); }
	static Colour spunPearl() { return Colour(170, 171, 183, 255); }
	static Colour squirrel() { return Colour(143, 129, 118, 255); }
	static Colour stTropaz() { return Colour(45, 86, 155, 255); }
	static Colour stack() { return Colour(138, 143, 138, 255); }
	static Colour starDust() { return Colour(159, 159, 156, 255); }
	static Colour starkWhite() { return Colour(229, 215, 189, 255); }
	static Colour starship() { return Colour(236, 242, 69, 255); }
	static Colour steelGrey() { return Colour(38, 35, 53, 255); }
	static Colour stiletto() { return Colour(156, 51, 54, 255); }
	static Colour stinger() { return Colour(139, 107, 11, 255); }
	static Colour stonewall() { return Colour(146, 133, 115, 255); }
	static Colour stormDust() { return Colour(100, 100, 99, 255); }
	static Colour stormGrey() { return Colour(113, 116, 134, 255); }
	static Colour stratos() { return Colour(0, 7, 65, 255); }
	static Colour straw() { return Colour(212, 191, 141, 255); }
	static Colour strikemaster() { return Colour(149, 99, 135, 255); }
	static Colour stromboli() { return Colour(50, 93, 82, 255); }
	static Colour studio() { return Colour(113, 74, 178, 255); }
	static Colour submarine() { return Colour(186, 199, 201, 255); }
	static Colour sugarCane() { return Colour(249, 255, 246, 255); }
	static Colour sulu() { return Colour(193, 240, 124, 255); }
	static Colour summerGreen() { return Colour(150, 187, 171, 255); }
	static Colour sun() { return Colour(251, 172, 19, 255); }
	static Colour sundance() { return Colour(201, 179, 91, 255); }
	static Colour sundown() { return Colour(255, 177, 179, 255); }
	static Colour sunflower() { return Colour(228, 212, 34, 255); }
	static Colour sunglo() { return Colour(225, 104, 101, 255); }
	static Colour sunset() { return Colour(220, 67, 51, 255); }
	static Colour sunshade() { return Colour(255, 158, 44, 255); }
	static Colour supernova() { return Colour(255, 201, 1, 255); }
	static Colour surf() { return Colour(187, 215, 193, 255); }
	static Colour surfCrest() { return Colour(207, 229, 210, 255); }
	static Colour surfieGreen() { return Colour(12, 122, 121, 255); }
	static Colour sushi() { return Colour(135, 171, 57, 255); }
	static Colour suvaGrey() { return Colour(136, 131, 135, 255); }
	static Colour swamp() { return Colour(0, 27, 28, 255); }
	static Colour swansDown() { return Colour(220, 240, 234, 255); }
	static Colour sweetCorn() { return Colour(251, 234, 140, 255); }
	static Colour sweetPink() { return Colour(253, 159, 162, 255); }
	static Colour swirl() { return Colour(211, 205, 197, 255); }
	static Colour swissCoffee() { return Colour(221, 214, 213, 255); }
	static Colour sycamore() { return Colour(144, 141, 57, 255); }
	static Colour tabasco() { return Colour(160, 39, 18, 255); }
	static Colour tacao() { return Colour(237, 179, 129, 255); }
	static Colour tacha() { return Colour(214, 197, 98, 255); }
	static Colour tahitiGold() { return Colour(233, 124, 7, 255); }
	static Colour tahunaSands() { return Colour(238, 240, 200, 255); }
	static Colour tallPoppy() { return Colour(179, 45, 41, 255); }
	static Colour tallow() { return Colour(168, 165, 137, 255); }
	static Colour tamarillo() { return Colour(153, 22, 19, 255); }
	static Colour tamarind() { return Colour(52, 21, 21, 255); }
	static Colour tana() { return Colour(217, 220, 193, 255); }
	static Colour tangaroa() { return Colour(3, 22, 60, 255); }
	static Colour tangerine() { return Colour(233, 110, 0, 255); }
	static Colour tango() { return Colour(237, 122, 28, 255); }
	static Colour tapa() { return Colour(123, 120, 116, 255); }
	static Colour tapestry() { return Colour(176, 94, 129, 255); }
	static Colour tara() { return Colour(225, 246, 232, 255); }
	static Colour tarawera() { return Colour(7, 58, 80, 255); }
	static Colour tasman() { return Colour(207, 220, 207, 255); }
	static Colour taupeGrey() { return Colour(179, 175, 149, 255); }
	static Colour tawnyPort() { return Colour(105, 37, 69, 255); }
	static Colour taxBreak() { return Colour(81, 128, 143, 255); }
	static Colour tePapaGreen() { return Colour(30, 67, 60, 255); }
	static Colour tea() { return Colour(193, 186, 176, 255); }
	static Colour teak() { return Colour(177, 148, 97, 255); }
	static Colour teakWoodFinish() { return Colour(107, 42, 20, 255); }
	static Colour tealBlue() { return Colour(4, 66, 89, 255); }
	static Colour temptress() { return Colour(59, 0, 11, 255); }
	static Colour tequila() { return Colour(255, 230, 199, 255); }
	static Colour texas() { return Colour(248, 249, 156, 255); }
	static Colour texasRose() { return Colour(255, 181, 85, 255); }
	static Colour thatch() { return Colour(182, 157, 152, 255); }
	static Colour thatchGreen() { return Colour(64, 61, 25, 255); }
	static Colour thistle() { return Colour(204, 202, 168, 255); }
	static Colour thunder() { return Colour(51, 41, 47, 255); }
	static Colour thunderbird() { return Colour(192, 43, 24, 255); }
	static Colour tiaMaria() { return Colour(193, 68, 14, 255); }
	static Colour tiara() { return Colour(195, 209, 209, 255); }
	static Colour tiber() { return Colour(6, 53, 55, 255); }
	static Colour tidal() { return Colour(241, 255, 173, 255); }
	static Colour tide() { return Colour(191, 184, 176, 255); }
	static Colour timberGreen() { return Colour(22, 50, 44, 255); }
	static Colour titanWhite() { return Colour(240, 238, 255, 255); }
	static Colour toast() { return Colour(154, 110, 97, 255); }
	static Colour tobaccoBrown() { return Colour(113, 93, 71, 255); }
	static Colour tobago() { return Colour(62, 43, 35, 255); }
	static Colour toledo() { return Colour(58, 0, 32, 255); }
	static Colour tolopea() { return Colour(27, 2, 69, 255); }
	static Colour tomThumb() { return Colour(63, 88, 59, 255); }
	static Colour tonysPink() { return Colour(231, 159, 140, 255); }
	static Colour topaz() { return Colour(124, 119, 138, 255); }
	static Colour toreaBay() { return Colour(15, 45, 158, 255); }
	static Colour toryBlue() { return Colour(20, 80, 170, 255); }
	static Colour tosca() { return Colour(141, 63, 63, 255); }
	static Colour totemPole() { return Colour(153, 27, 7, 255); }
	static Colour touchWood() { return Colour(55, 48, 33, 255); }
	static Colour towerGrey() { return Colour(169, 189, 191, 255); }
	static Colour tradewind() { return Colour(95, 179, 172, 255); }
	static Colour tranquil() { return Colour(230, 255, 255, 255); }
	static Colour travertine() { return Colour(255, 253, 232, 255); }
	static Colour treePoppy() { return Colour(252, 156, 29, 255); }
	static Colour treehouse() { return Colour(59, 40, 32, 255); }
	static Colour trendyGreen() { return Colour(124, 136, 26, 255); }
	static Colour trendyPink() { return Colour(140, 100, 149, 255); }
	static Colour trinidad() { return Colour(230, 78, 3, 255); }
	static Colour tropicalBlue() { return Colour(195, 221, 249, 255); }
	static Colour trout() { return Colour(74, 78, 90, 255); }
	static Colour trueV() { return Colour(138, 115, 214, 255); }
	static Colour tuatara() { return Colour(54, 53, 52, 255); }
	static Colour tuftBush() { return Colour(255, 221, 205, 255); }
	static Colour tulipTree() { return Colour(234, 179, 59, 255); }
	static Colour tumbleweed() { return Colour(55, 41, 14, 255); }
	static Colour tuna() { return Colour(53, 53, 66, 255); }
	static Colour tundora() { return Colour(74, 66, 68, 255); }
	static Colour turbo() { return Colour(250, 230, 0, 255); }
	static Colour turkishRose() { return Colour(181, 114, 129, 255); }
	static Colour turmeric() { return Colour(202, 187, 72, 255); }
	static Colour turtleGreen() { return Colour(42, 56, 11, 255); }
	static Colour tuscany() { return Colour(189, 94, 46, 255); }
	static Colour tusk() { return Colour(238, 243, 195, 255); }
	static Colour tussock() { return Colour(197, 153, 75, 255); }
	static Colour tutu() { return Colour(255, 241, 249, 255); }
	static Colour twilight() { return Colour(228, 207, 222, 255); }
	static Colour twilightBlue() { return Colour(238, 253, 255, 255); }
	static Colour twine() { return Colour(194, 149, 93, 255); }
	static Colour valencia() { return Colour(216, 68, 55, 255); }
	static Colour valentino() { return Colour(53, 14, 66, 255); }
	static Colour valhalla() { return Colour(43, 25, 79, 255); }
	static Colour vanCleef() { return Colour(73, 23, 12, 255); }
	static Colour vanilla() { return Colour(209, 190, 168, 255); }
	static Colour vanillaIce() { return Colour(243, 217, 223, 255); }
	static Colour varden() { return Colour(255, 246, 223, 255); }
	static Colour venetianRed() { return Colour(114, 1, 15, 255); }
	static Colour veniceBlue() { return Colour(5, 89, 137, 255); }
	static Colour venus() { return Colour(146, 133, 144, 255); }
	static Colour verdigris() { return Colour(93, 94, 55, 255); }
	static Colour verdunGreen() { return Colour(73, 84, 0, 255); }
	static Colour vesuvius() { return Colour(177, 74, 11, 255); }
	static Colour victoria() { return Colour(83, 68, 145, 255); }
	static Colour vidaLoca() { return Colour(84, 144, 25, 255); }
	static Colour viking() { return Colour(100, 204, 219, 255); }
	static Colour vinRouge() { return Colour(152, 61, 97, 255); }
	static Colour viola() { return Colour(203, 143, 169, 255); }
	static Colour violentViolet() { return Colour(41, 12, 94, 255); }
	static Colour violet() { return Colour(36, 10, 64, 255); }
	static Colour viridianGreen() { return Colour(103, 137, 117, 255); }
	static Colour visVis() { return Colour(255, 239, 161, 255); }
	static Colour vistaBlue() { return Colour(143, 214, 180, 255); }
	static Colour vistaWhite() { return Colour(252, 248, 247, 255); }
	static Colour volcano() { return Colour(101, 26, 20, 255); }
	static Colour voodoo() { return Colour(83, 52, 85, 255); }
	static Colour vulcan() { return Colour(16, 18, 29, 255); }
	static Colour wafer() { return Colour(222, 203, 198, 255); }
	static Colour waikawaGrey() { return Colour(90, 110, 156, 255); }
	static Colour waiouru() { return Colour(54, 60, 13, 255); }
	static Colour walnut() { return Colour(119, 63, 26, 255); }
	static Colour wanWhite() { return Colour(252, 255, 249, 255); }
	static Colour wasabi() { return Colour(120, 138, 37, 255); }
	static Colour waterLeaf() { return Colour(161, 233, 222, 255); }
	static Colour watercourse() { return Colour(5, 111, 87, 255); }
	static Colour waterloo() { return Colour(123, 124, 148, 255); }
	static Colour wattle() { return Colour(220, 215, 71, 255); }
	static Colour watusi() { return Colour(255, 221, 207, 255); }
	static Colour waxFlower() { return Colour(255, 192, 168, 255); }
	static Colour wePeep() { return Colour(247, 219, 230, 255); }
	static Colour wedgewood() { return Colour(78, 127, 158, 255); }
	static Colour wellRead() { return Colour(180, 51, 50, 255); }
	static Colour westCoast() { return Colour(98, 81, 25, 255); }
	static Colour westSide() { return Colour(255, 145, 15, 255); }
	static Colour westar() { return Colour(220, 217, 210, 255); }
	static Colour westernRed() { return Colour(139, 7, 35, 255); }
	static Colour wewak() { return Colour(241, 155, 171, 255); }
	static Colour wheatfield() { return Colour(243, 237, 207, 255); }
	static Colour whiskey() { return Colour(213, 154, 111, 255); }
	static Colour whiskeySour() { return Colour(219, 153, 94, 255); }
	static Colour whisper() { return Colour(247, 245, 250, 255); }
	static Colour whiteIce() { return Colour(221, 249, 241, 255); }
	static Colour whiteLilac() { return Colour(248, 247, 252, 255); }
	static Colour whiteLinen() { return Colour(248, 240, 232, 255); }
	static Colour whiteNectar() { return Colour(252, 255, 231, 255); }
	static Colour whitePointer() { return Colour(254, 248, 255, 255); }
	static Colour whiteRock() { return Colour(234, 232, 212, 255); }
	static Colour wildRice() { return Colour(236, 224, 144, 255); }
	static Colour wildSand() { return Colour(244, 244, 244, 255); }
	static Colour wildWillow() { return Colour(185, 196, 106, 255); }
	static Colour william() { return Colour(58, 104, 108, 255); }
	static Colour willowBrook() { return Colour(223, 236, 218, 255); }
	static Colour willowGrove() { return Colour(101, 116, 93, 255); }
	static Colour windsor() { return Colour(60, 8, 120, 255); }
	static Colour wineBerry() { return Colour(89, 29, 53, 255); }
	static Colour winterHazel() { return Colour(213, 209, 149, 255); }
	static Colour wispPink() { return Colour(254, 244, 248, 255); }
	static Colour wisteria() { return Colour(151, 113, 181, 255); }
	static Colour wistful() { return Colour(164, 166, 211, 255); }
	static Colour witchHaze() { return Colour(255, 252, 153, 255); }
	static Colour woodBark() { return Colour(38, 17, 5, 255); }
	static Colour woodburn() { return Colour(60, 32, 5, 255); }
	static Colour woodland() { return Colour(77, 83, 40, 255); }
	static Colour woodrush() { return Colour(48, 42, 15, 255); }
	static Colour woodsmoke() { return Colour(12, 13, 15, 255); }
	static Colour woodyBay() { return Colour(41, 33, 48, 255); }
	static Colour woodyBrown() { return Colour(72, 49, 49, 255); }
	static Colour xanadu() { return Colour(115, 134, 120, 255); }
	static Colour yellowMetal() { return Colour(113, 99, 56, 255); }
	static Colour yellowSea() { return Colour(254, 169, 4, 255); }
	static Colour yourPink() { return Colour(255, 195, 192, 255); }
	static Colour yukonGold() { return Colour(123, 102, 8, 255); }
	static Colour yuma() { return Colour(206, 194, 145, 255); }
	static Colour zambezi() { return Colour(104, 85, 88, 255); }
	static Colour zanah() { return Colour(218, 236, 214, 255); }
	static Colour zest() { return Colour(229, 132, 27, 255); }
	static Colour zeus() { return Colour(41, 35, 25, 255); }
	static Colour ziggurat() { return Colour(191, 219, 226, 255); }
	static Colour zircon() { return Colour(244, 248, 255, 255); }
	static Colour zombie() { return Colour(228, 214, 155, 255); }
	static Colour zorba() { return Colour(165, 155, 145, 255); }
	static Colour zuccini() { return Colour(4, 64, 34, 255); }
	static Colour zumthor() { return Colour(237, 246, 255, 255); }
	static Colour zydeco() { return Colour(2, 64, 44, 255); }
	}
	static Colour[string] colours(){if(_colours is null) _colours = [
"abbey": Colours.abbey,
"acadia": Colours.acadia,
"acapulco": Colours.acapulco,
"acorn": Colours.acorn,
"aeroBlue": Colours.aeroBlue,
"affair": Colours.affair,
"afghanTan": Colours.afghanTan,
"akaroa": Colours.akaroa,
"alabaster": Colours.alabaster,
"albescentWhite": Colours.albescentWhite,
"alertTan": Colours.alertTan,
"allports": Colours.allports,
"almondFrost": Colours.almondFrost,
"alpine": Colours.alpine,
"alto": Colours.alto,
"aluminium": Colours.aluminium,
"amazon": Colours.amazon,
"americano": Colours.americano,
"amethystSmoke": Colours.amethystSmoke,
"amour": Colours.amour,
"amulet": Colours.amulet,
"anakiwa": Colours.anakiwa,
"antiqueBrass": Colours.antiqueBrass,
"anzac": Colours.anzac,
"apache": Colours.apache,
"apple": Colours.apple,
"appleBlossom": Colours.appleBlossom,
"appleGreen": Colours.appleGreen,
"apricot": Colours.apricot,
"apricotWhite": Colours.apricotWhite,
"aqua": Colours.aqua,
"aquaHaze": Colours.aquaHaze,
"aquaSpring": Colours.aquaSpring,
"aquaSqueeze": Colours.aquaSqueeze,
"aquamarine": Colours.aquamarine,
"arapawa": Colours.arapawa,
"armadillo": Colours.armadillo,
"arrowtown": Colours.arrowtown,
"ash": Colours.ash,
"ashBrown": Colours.ashBrown,
"asphalt": Colours.asphalt,
"astra": Colours.astra,
"astral": Colours.astral,
"astronaut": Colours.astronaut,
"astronautBlue": Colours.astronautBlue,
"athensGrey": Colours.athensGrey,
"athsSpecial": Colours.athsSpecial,
"atlantis": Colours.atlantis,
"atoll": Colours.atoll,
"atomic": Colours.atomic,
"auChico": Colours.auChico,
"aubergine": Colours.aubergine,
"australianMint": Colours.australianMint,
"avocado": Colours.avocado,
"axolotl": Colours.axolotl,
"azalea": Colours.azalea,
"aztec": Colours.aztec,
"azure": Colours.azure,
"bahamaBlue": Colours.bahamaBlue,
"bahia": Colours.bahia,
"bajaWhite": Colours.bajaWhite,
"baliHai": Colours.baliHai,
"balticSea": Colours.balticSea,
"bamboo": Colours.bamboo,
"bandicoot": Colours.bandicoot,
"banjul": Colours.banjul,
"barberry": Colours.barberry,
"barleyCorn": Colours.barleyCorn,
"barleyWhite": Colours.barleyWhite,
"barossa": Colours.barossa,
"bastille": Colours.bastille,
"battleshipGrey": Colours.battleshipGrey,
"bayLeaf": Colours.bayLeaf,
"bayofMany": Colours.bayofMany,
"bazaar": Colours.bazaar,
"bean": Colours.bean,
"beautyBush": Colours.beautyBush,
"beeswax": Colours.beeswax,
"bermuda": Colours.bermuda,
"bermudaGrey": Colours.bermudaGrey,
"berylGreen": Colours.berylGreen,
"bianca": Colours.bianca,
"bigStone": Colours.bigStone,
"bilbao": Colours.bilbao,
"bilobaFlower": Colours.bilobaFlower,
"birch": Colours.birch,
"birdFlower": Colours.birdFlower,
"biscay": Colours.biscay,
"bismark": Colours.bismark,
"bisonHide": Colours.bisonHide,
"bitter": Colours.bitter,
"bitterLemon": Colours.bitterLemon,
"bizarre": Colours.bizarre,
"blackBean": Colours.blackBean,
"blackForest": Colours.blackForest,
"blackHaze": Colours.blackHaze,
"blackMagic": Colours.blackMagic,
"blackMarlin": Colours.blackMarlin,
"blackPearl": Colours.blackPearl,
"blackPepper": Colours.blackPepper,
"blackRock": Colours.blackRock,
"blackRose": Colours.blackRose,
"blackRussian": Colours.blackRussian,
"blackSqueeze": Colours.blackSqueeze,
"blackWhite": Colours.blackWhite,
"blackberry": Colours.blackberry,
"blackcurrant": Colours.blackcurrant,
"blackwood": Colours.blackwood,
"blanc": Colours.blanc,
"bleachWhite": Colours.bleachWhite,
"bleachedCedar": Colours.bleachedCedar,
"blossom": Colours.blossom,
"blueBark": Colours.blueBark,
"blueBayoux": Colours.blueBayoux,
"blueBell": Colours.blueBell,
"blueChalk": Colours.blueChalk,
"blueCharcoal": Colours.blueCharcoal,
"blueChill": Colours.blueChill,
"blueDiamond": Colours.blueDiamond,
"blueDianne": Colours.blueDianne,
"blueGem": Colours.blueGem,
"blueHaze": Colours.blueHaze,
"blueLagoon": Colours.blueLagoon,
"blueMarguerite": Colours.blueMarguerite,
"blueRomance": Colours.blueRomance,
"blueSmoke": Colours.blueSmoke,
"blueStone": Colours.blueStone,
"blueWhale": Colours.blueWhale,
"blueZodiac": Colours.blueZodiac,
"blumine": Colours.blumine,
"blush": Colours.blush,
"bokaraGrey": Colours.bokaraGrey,
"bombay": Colours.bombay,
"bonJour": Colours.bonJour,
"bondiBlue": Colours.bondiBlue,
"bone": Colours.bone,
"bordeaux": Colours.bordeaux,
"bossanova": Colours.bossanova,
"bostonBlue": Colours.bostonBlue,
"botticelli": Colours.botticelli,
"bottleGreen": Colours.bottleGreen,
"boulder": Colours.boulder,
"bouquet": Colours.bouquet,
"bourbon": Colours.bourbon,
"bracken": Colours.bracken,
"brandy": Colours.brandy,
"brandyPunch": Colours.brandyPunch,
"brandyRose": Colours.brandyRose,
"brazil": Colours.brazil,
"breakerBay": Colours.breakerBay,
"bridalHeath": Colours.bridalHeath,
"bridesmaid": Colours.bridesmaid,
"brightGrey": Colours.brightGrey,
"brightRed": Colours.brightRed,
"brightSun": Colours.brightSun,
"bronco": Colours.bronco,
"bronze": Colours.bronze,
"bronzeOlive": Colours.bronzeOlive,
"bronzetone": Colours.bronzetone,
"broom": Colours.broom,
"brownBramble": Colours.brownBramble,
"brownDerby": Colours.brownDerby,
"brownPod": Colours.brownPod,
"bubbles": Colours.bubbles,
"buccaneer": Colours.buccaneer,
"bud": Colours.bud,
"buddhaGold": Colours.buddhaGold,
"bulgarianRose": Colours.bulgarianRose,
"bullShot": Colours.bullShot,
"bunker": Colours.bunker,
"bunting": Colours.bunting,
"burgundy": Colours.burgundy,
"burnham": Colours.burnham,
"burningSand": Colours.burningSand,
"burntCrimson": Colours.burntCrimson,
"bush": Colours.bush,
"buttercup": Colours.buttercup,
"butteredRum": Colours.butteredRum,
"butterflyBush": Colours.butterflyBush,
"buttermilk": Colours.buttermilk,
"butteryWhite": Colours.butteryWhite,
"cabSav": Colours.cabSav,
"cabaret": Colours.cabaret,
"cabbagePont": Colours.cabbagePont,
"cactus": Colours.cactus,
"cadillac": Colours.cadillac,
"cafeRoyale": Colours.cafeRoyale,
"calico": Colours.calico,
"california": Colours.california,
"calypso": Colours.calypso,
"camarone": Colours.camarone,
"camelot": Colours.camelot,
"cameo": Colours.cameo,
"camouflage": Colours.camouflage,
"canCan": Colours.canCan,
"canary": Colours.canary,
"candlelight": Colours.candlelight,
"cannonBlack": Colours.cannonBlack,
"cannonPink": Colours.cannonPink,
"canvas": Colours.canvas,
"capeCod": Colours.capeCod,
"capeHoney": Colours.capeHoney,
"capePalliser": Colours.capePalliser,
"caper": Colours.caper,
"capri": Colours.capri,
"caramel": Colours.caramel,
"cararra": Colours.cararra,
"cardinGreen": Colours.cardinGreen,
"cardinal": Colours.cardinal,
"careysPink": Colours.careysPink,
"carissma": Colours.carissma,
"carla": Colours.carla,
"carnabyTan": Colours.carnabyTan,
"carouselPink": Colours.carouselPink,
"casablanca": Colours.casablanca,
"casal": Colours.casal,
"cascade": Colours.cascade,
"cashmere": Colours.cashmere,
"casper": Colours.casper,
"castro": Colours.castro,
"catalinaBlue": Colours.catalinaBlue,
"catskillWhite": Colours.catskillWhite,
"cavernPink": Colours.cavernPink,
"ceSoir": Colours.ceSoir,
"cedar": Colours.cedar,
"cedarWoodFinish": Colours.cedarWoodFinish,
"celery": Colours.celery,
"celeste": Colours.celeste,
"cello": Colours.cello,
"celtic": Colours.celtic,
"cement": Colours.cement,
"ceramic": Colours.ceramic,
"chablis": Colours.chablis,
"chaletGreen": Colours.chaletGreen,
"chalky": Colours.chalky,
"chambray": Colours.chambray,
"chamois": Colours.chamois,
"champagne": Colours.champagne,
"chantilly": Colours.chantilly,
"charade": Colours.charade,
"chardon": Colours.chardon,
"chardonnay": Colours.chardonnay,
"charlotte": Colours.charlotte,
"charm": Colours.charm,
"chateauGreen": Colours.chateauGreen,
"chatelle": Colours.chatelle,
"chathamsBlue": Colours.chathamsBlue,
"chelseaCucumber": Colours.chelseaCucumber,
"chelseaGem": Colours.chelseaGem,
"chenin": Colours.chenin,
"cherokee": Colours.cherokee,
"cherryPie": Colours.cherryPie,
"cherrywood": Colours.cherrywood,
"cherub": Colours.cherub,
"chetwodeBlue": Colours.chetwodeBlue,
"chicago": Colours.chicago,
"chiffon": Colours.chiffon,
"chileanFire": Colours.chileanFire,
"chileanHeath": Colours.chileanHeath,
"chinaIvory": Colours.chinaIvory,
"chino": Colours.chino,
"chinook": Colours.chinook,
"chocolate": Colours.chocolate,
"christalle": Colours.christalle,
"christi": Colours.christi,
"christine": Colours.christine,
"chromeWhite": Colours.chromeWhite,
"cigar": Colours.cigar,
"cinder": Colours.cinder,
"cinderella": Colours.cinderella,
"cinnamon": Colours.cinnamon,
"cioccolato": Colours.cioccolato,
"citrineWhite": Colours.citrineWhite,
"citron": Colours.citron,
"citrus": Colours.citrus,
"clairvoyant": Colours.clairvoyant,
"clamShell": Colours.clamShell,
"claret": Colours.claret,
"classicRose": Colours.classicRose,
"clayCreek": Colours.clayCreek,
"clearDay": Colours.clearDay,
"clementine": Colours.clementine,
"clinker": Colours.clinker,
"cloud": Colours.cloud,
"cloudBurst": Colours.cloudBurst,
"cloudy": Colours.cloudy,
"clover": Colours.clover,
"cobalt": Colours.cobalt,
"cocoaBean": Colours.cocoaBean,
"cocoaBrown": Colours.cocoaBrown,
"coconutCream": Colours.coconutCream,
"codGrey": Colours.codGrey,
"coffee": Colours.coffee,
"coffeeBean": Colours.coffeeBean,
"cognac": Colours.cognac,
"cola": Colours.cola,
"coldPurple": Colours.coldPurple,
"coldTurkey": Colours.coldTurkey,
"colonialWhite": Colours.colonialWhite,
"comet": Colours.comet,
"como": Colours.como,
"conch": Colours.conch,
"concord": Colours.concord,
"concrete": Colours.concrete,
"confetti": Colours.confetti,
"congoBrown": Colours.congoBrown,
"conifer": Colours.conifer,
"contessa": Colours.contessa,
"copperCanyon": Colours.copperCanyon,
"copperRust": Colours.copperRust,
"coral": Colours.coral,
"coralCandy": Colours.coralCandy,
"coralTree": Colours.coralTree,
"corduroy": Colours.corduroy,
"coriander": Colours.coriander,
"cork": Colours.cork,
"corn": Colours.corn,
"cornField": Colours.cornField,
"cornHarvest": Colours.cornHarvest,
"cornflower": Colours.cornflower,
"corvette": Colours.corvette,
"cosmic": Colours.cosmic,
"cosmos": Colours.cosmos,
"costaDelSol": Colours.costaDelSol,
"cottonSeed": Colours.cottonSeed,
"countyGreen": Colours.countyGreen,
"coveGrey": Colours.coveGrey,
"cowboy": Colours.cowboy,
"crabApple": Colours.crabApple,
"crail": Colours.crail,
"cranberry": Colours.cranberry,
"craterBrown": Colours.craterBrown,
"creamBrulee": Colours.creamBrulee,
"creamCan": Colours.creamCan,
"cremeDeBanane": Colours.cremeDeBanane,
"creole": Colours.creole,
"crete": Colours.crete,
"crocodile": Colours.crocodile,
"crownofThorns": Colours.crownofThorns,
"crowshead": Colours.crowshead,
"cruise": Colours.cruise,
"crusoe": Colours.crusoe,
"crusta": Colours.crusta,
"cubanTan": Colours.cubanTan,
"cumin": Colours.cumin,
"cumulus": Colours.cumulus,
"cupid": Colours.cupid,
"curiousBlue": Colours.curiousBlue,
"cuttySark": Colours.cuttySark,
"cyprus": Colours.cyprus,
"daintree": Colours.daintree,
"dairyCream": Colours.dairyCream,
"daisyBush": Colours.daisyBush,
"dallas": Colours.dallas,
"danube": Colours.danube,
"darkEbony": Colours.darkEbony,
"darkOak": Colours.darkOak,
"darkRimu": Colours.darkRimu,
"darkRum": Colours.darkRum,
"darkSlate": Colours.darkSlate,
"darkTan": Colours.darkTan,
"dawn": Colours.dawn,
"dawnPink": Colours.dawnPink,
"deYork": Colours.deYork,
"deco": Colours.deco,
"deepBlush": Colours.deepBlush,
"deepBronze": Colours.deepBronze,
"deepCove": Colours.deepCove,
"deepFir": Colours.deepFir,
"deepKoamaru": Colours.deepKoamaru,
"deepOak": Colours.deepOak,
"deepSea": Colours.deepSea,
"deepTeal": Colours.deepTeal,
"delRio": Colours.delRio,
"dell": Colours.dell,
"delta": Colours.delta,
"deluge": Colours.deluge,
"derby": Colours.derby,
"desert": Colours.desert,
"desertStorm": Colours.desertStorm,
"dew": Colours.dew,
"diSerria": Colours.diSerria,
"diesel": Colours.diesel,
"dingley": Colours.dingley,
"disco": Colours.disco,
"dixie": Colours.dixie,
"dolly": Colours.dolly,
"dolphin": Colours.dolphin,
"domino": Colours.domino,
"donJuan": Colours.donJuan,
"donkeyBrown": Colours.donkeyBrown,
"dorado": Colours.dorado,
"doubleColonialWhite": Colours.doubleColonialWhite,
"doublePearlLusta": Colours.doublePearlLusta,
"doubleSpanishWhite": Colours.doubleSpanishWhite,
"doveGrey": Colours.doveGrey,
"downriver": Colours.downriver,
"downy": Colours.downy,
"driftwood": Colours.driftwood,
"drover": Colours.drover,
"dune": Colours.dune,
"dustStorm": Colours.dustStorm,
"dustyGrey": Colours.dustyGrey,
"dutchWhite": Colours.dutchWhite,
"eagle": Colours.eagle,
"earlsGreen": Colours.earlsGreen,
"earlyDawn": Colours.earlyDawn,
"eastBay": Colours.eastBay,
"eastSide": Colours.eastSide,
"easternBlue": Colours.easternBlue,
"ebb": Colours.ebb,
"ebony": Colours.ebony,
"ebonyClay": Colours.ebonyClay,
"echoBlue": Colours.echoBlue,
"eclipse": Colours.eclipse,
"ecruWhite": Colours.ecruWhite,
"ecstasy": Colours.ecstasy,
"eden": Colours.eden,
"edgewater": Colours.edgewater,
"edward": Colours.edward,
"eggSour": Colours.eggSour,
"eggWhite": Colours.eggWhite,
"elPaso": Colours.elPaso,
"elSalva": Colours.elSalva,
"elephant": Colours.elephant,
"elfGreen": Colours.elfGreen,
"elm": Colours.elm,
"embers": Colours.embers,
"eminence": Colours.eminence,
"emperor": Colours.emperor,
"empress": Colours.empress,
"endeavour": Colours.endeavour,
"energyYellow": Colours.energyYellow,
"englishHolly": Colours.englishHolly,
"englishWalnut": Colours.englishWalnut,
"envy": Colours.envy,
"equator": Colours.equator,
"espresso": Colours.espresso,
"eternity": Colours.eternity,
"eucalyptus": Colours.eucalyptus,
"eunry": Colours.eunry,
"eveningSea": Colours.eveningSea,
"everglade": Colours.everglade,
"fairPink": Colours.fairPink,
"falcon": Colours.falcon,
"fantasy": Colours.fantasy,
"fedora": Colours.fedora,
"feijoa": Colours.feijoa,
"fern": Colours.fern,
"fernFrond": Colours.fernFrond,
"ferra": Colours.ferra,
"festival": Colours.festival,
"feta": Colours.feta,
"fieryOrange": Colours.fieryOrange,
"fijiGreen": Colours.fijiGreen,
"finch": Colours.finch,
"finlandia": Colours.finlandia,
"finn": Colours.finn,
"fiord": Colours.fiord,
"fire": Colours.fire,
"fireBush": Colours.fireBush,
"firefly": Colours.firefly,
"flamePea": Colours.flamePea,
"flameRed": Colours.flameRed,
"flamenco": Colours.flamenco,
"flamingo": Colours.flamingo,
"flax": Colours.flax,
"flint": Colours.flint,
"flirt": Colours.flirt,
"foam": Colours.foam,
"fog": Colours.fog,
"foggyGrey": Colours.foggyGrey,
"forestGreen": Colours.forestGreen,
"forgetMeNot": Colours.forgetMeNot,
"fountainBlue": Colours.fountainBlue,
"frangipani": Colours.frangipani,
"frenchGrey": Colours.frenchGrey,
"frenchLilac": Colours.frenchLilac,
"frenchPass": Colours.frenchPass,
"friarGrey": Colours.friarGrey,
"fringyFlower": Colours.fringyFlower,
"froly": Colours.froly,
"frost": Colours.frost,
"frostedMint": Colours.frostedMint,
"frostee": Colours.frostee,
"fruitSalad": Colours.fruitSalad,
"fuchsia": Colours.fuchsia,
"fuego": Colours.fuego,
"fuelYellow": Colours.fuelYellow,
"funBlue": Colours.funBlue,
"funGreen": Colours.funGreen,
"fuscousGrey": Colours.fuscousGrey,
"gableGreen": Colours.gableGreen,
"gallery": Colours.gallery,
"galliano": Colours.galliano,
"geebung": Colours.geebung,
"genoa": Colours.genoa,
"geraldine": Colours.geraldine,
"geyser": Colours.geyser,
"ghost": Colours.ghost,
"gigas": Colours.gigas,
"gimblet": Colours.gimblet,
"gin": Colours.gin,
"ginFizz": Colours.ginFizz,
"givry": Colours.givry,
"glacier": Colours.glacier,
"gladeGreen": Colours.gladeGreen,
"goBen": Colours.goBen,
"goblin": Colours.goblin,
"goldDrop": Colours.goldDrop,
"goldTips": Colours.goldTips,
"goldenBell": Colours.goldenBell,
"goldenDream": Colours.goldenDream,
"goldenFizz": Colours.goldenFizz,
"goldenGlow": Colours.goldenGlow,
"goldenSand": Colours.goldenSand,
"goldenTainoi": Colours.goldenTainoi,
"gondola": Colours.gondola,
"gordonsGreen": Colours.gordonsGreen,
"gorse": Colours.gorse,
"gossamer": Colours.gossamer,
"gossip": Colours.gossip,
"gothic": Colours.gothic,
"governorBay": Colours.governorBay,
"grainBrown": Colours.grainBrown,
"grandis": Colours.grandis,
"graniteGreen": Colours.graniteGreen,
"grannyApple": Colours.grannyApple,
"grannySmith": Colours.grannySmith,
"grape": Colours.grape,
"graphite": Colours.graphite,
"grassHopper": Colours.grassHopper,
"gravel": Colours.gravel,
"greenHouse": Colours.greenHouse,
"greenKelp": Colours.greenKelp,
"greenLeaf": Colours.greenLeaf,
"greenMist": Colours.greenMist,
"greenPea": Colours.greenPea,
"greenSmoke": Colours.greenSmoke,
"greenSpring": Colours.greenSpring,
"greenVogue": Colours.greenVogue,
"greenWaterloo": Colours.greenWaterloo,
"greenWhite": Colours.greenWhite,
"greenstone": Colours.greenstone,
"grenadier": Colours.grenadier,
"greyChateau": Colours.greyChateau,
"greyGreen": Colours.greyGreen,
"greyNickel": Colours.greyNickel,
"greyNurse": Colours.greyNurse,
"greyOlive": Colours.greyOlive,
"greySuit": Colours.greySuit,
"guardsmanRed": Colours.guardsmanRed,
"gulfBlue": Colours.gulfBlue,
"gulfStream": Colours.gulfStream,
"gullGrey": Colours.gullGrey,
"gumLeaf": Colours.gumLeaf,
"gumbo": Colours.gumbo,
"gunPowder": Colours.gunPowder,
"gunmetal": Colours.gunmetal,
"gunsmoke": Colours.gunsmoke,
"gurkha": Colours.gurkha,
"hacienda": Colours.hacienda,
"hairyHeath": Colours.hairyHeath,
"haiti": Colours.haiti,
"halfandHalf": Colours.halfandHalf,
"halfBaked": Colours.halfBaked,
"halfColonialWhite": Colours.halfColonialWhite,
"halfDutchWhite": Colours.halfDutchWhite,
"halfPearlLusta": Colours.halfPearlLusta,
"halfSpanishWhite": Colours.halfSpanishWhite,
"hampton": Colours.hampton,
"harp": Colours.harp,
"harvestGold": Colours.harvestGold,
"havana": Colours.havana,
"havelockBlue": Colours.havelockBlue,
"hawaiianTan": Colours.hawaiianTan,
"hawkesBlue": Colours.hawkesBlue,
"heath": Colours.heath,
"heather": Colours.heather,
"heatheredGrey": Colours.heatheredGrey,
"heavyMetal": Colours.heavyMetal,
"hemlock": Colours.hemlock,
"hemp": Colours.hemp,
"hibiscus": Colours.hibiscus,
"highball": Colours.highball,
"highland": Colours.highland,
"hillary": Colours.hillary,
"himalaya": Colours.himalaya,
"hintofGreen": Colours.hintofGreen,
"hintofGrey": Colours.hintofGrey,
"hintofRed": Colours.hintofRed,
"hintofYellow": Colours.hintofYellow,
"hippieBlue": Colours.hippieBlue,
"hippieGreen": Colours.hippieGreen,
"hippiePink": Colours.hippiePink,
"hitGrey": Colours.hitGrey,
"hitPink": Colours.hitPink,
"hokeyPokey": Colours.hokeyPokey,
"hoki": Colours.hoki,
"holly": Colours.holly,
"honeyFlower": Colours.honeyFlower,
"honeysuckle": Colours.honeysuckle,
"hopbush": Colours.hopbush,
"horizon": Colours.horizon,
"horsesNeck": Colours.horsesNeck,
"hotChile": Colours.hotChile,
"hotCurry": Colours.hotCurry,
"hotPurple": Colours.hotPurple,
"hotToddy": Colours.hotToddy,
"hummingBird": Colours.hummingBird,
"hunterGreen": Colours.hunterGreen,
"hurricane": Colours.hurricane,
"husk": Colours.husk,
"iceCold": Colours.iceCold,
"iceberg": Colours.iceberg,
"illusion": Colours.illusion,
"indianTan": Colours.indianTan,
"indochine": Colours.indochine,
"irishCoffee": Colours.irishCoffee,
"iroko": Colours.iroko,
"iron": Colours.iron,
"ironbark": Colours.ironbark,
"ironsideGrey": Colours.ironsideGrey,
"ironstone": Colours.ironstone,
"islandSpice": Colours.islandSpice,
"jacaranda": Colours.jacaranda,
"jacarta": Colours.jacarta,
"jackoBean": Colours.jackoBean,
"jacksonsPurple": Colours.jacksonsPurple,
"jade": Colours.jade,
"jaffa": Colours.jaffa,
"jaggedIce": Colours.jaggedIce,
"jagger": Colours.jagger,
"jaguar": Colours.jaguar,
"jambalaya": Colours.jambalaya,
"janna": Colours.janna,
"japaneseLaurel": Colours.japaneseLaurel,
"japaneseMaple": Colours.japaneseMaple,
"japonica": Colours.japonica,
"jarrah": Colours.jarrah,
"java": Colours.java,
"jazz": Colours.jazz,
"jellyBean": Colours.jellyBean,
"jetStream": Colours.jetStream,
"jewel": Colours.jewel,
"joanna": Colours.joanna,
"jon": Colours.jon,
"jonquil": Colours.jonquil,
"jordyBlue": Colours.jordyBlue,
"judgeGrey": Colours.judgeGrey,
"jumbo": Colours.jumbo,
"jungleGreen": Colours.jungleGreen,
"jungleMist": Colours.jungleMist,
"juniper": Colours.juniper,
"justRight": Colours.justRight,
"kabul": Colours.kabul,
"kaitokeGreen": Colours.kaitokeGreen,
"kangaroo": Colours.kangaroo,
"karaka": Colours.karaka,
"karry": Colours.karry,
"kashmirBlue": Colours.kashmirBlue,
"kelp": Colours.kelp,
"kenyanCopper": Colours.kenyanCopper,
"keppel": Colours.keppel,
"kidnapper": Colours.kidnapper,
"kilamanjaro": Colours.kilamanjaro,
"killarney": Colours.killarney,
"kimberly": Colours.kimberly,
"kingfisherDaisy": Colours.kingfisherDaisy,
"kobi": Colours.kobi,
"kokoda": Colours.kokoda,
"korma": Colours.korma,
"koromiko": Colours.koromiko,
"kournikova": Colours.kournikova,
"kumera": Colours.kumera,
"laPalma": Colours.laPalma,
"laRioja": Colours.laRioja,
"lasPalmas": Colours.lasPalmas,
"laser": Colours.laser,
"laurel": Colours.laurel,
"lavender": Colours.lavender,
"leather": Colours.leather,
"lemon": Colours.lemon,
"lemonGinger": Colours.lemonGinger,
"lemonGrass": Colours.lemonGrass,
"licorice": Colours.licorice,
"lightningYellow": Colours.lightningYellow,
"lilacBush": Colours.lilacBush,
"lily": Colours.lily,
"lilyWhite": Colours.lilyWhite,
"lima": Colours.lima,
"lime": Colours.lime,
"limeade": Colours.limeade,
"limedAsh": Colours.limedAsh,
"limedGum": Colours.limedGum,
"limedOak": Colours.limedOak,
"limedSpruce": Colours.limedSpruce,
"limerick": Colours.limerick,
"linen": Colours.linen,
"linkWater": Colours.linkWater,
"lipstick": Colours.lipstick,
"lisbonBrown": Colours.lisbonBrown,
"lividBrown": Colours.lividBrown,
"loafer": Colours.loafer,
"loblolly": Colours.loblolly,
"lochinvar": Colours.lochinvar,
"lochmara": Colours.lochmara,
"locust": Colours.locust,
"logCabin": Colours.logCabin,
"logan": Colours.logan,
"lola": Colours.lola,
"londonHue": Colours.londonHue,
"lonestar": Colours.lonestar,
"lotus": Colours.lotus,
"loulou": Colours.loulou,
"lucky": Colours.lucky,
"luckyPoint": Colours.luckyPoint,
"lunarGreen": Colours.lunarGreen,
"lusty": Colours.lusty,
"luxorGold": Colours.luxorGold,
"lynch": Colours.lynch,
"mabel": Colours.mabel,
"madang": Colours.madang,
"madison": Colours.madison,
"madras": Colours.madras,
"magnolia": Colours.magnolia,
"mahogany": Colours.mahogany,
"maiTai": Colours.maiTai,
"maire": Colours.maire,
"maize": Colours.maize,
"makara": Colours.makara,
"mako": Colours.mako,
"malachiteGreen": Colours.malachiteGreen,
"malibu": Colours.malibu,
"mallard": Colours.mallard,
"malta": Colours.malta,
"mamba": Colours.mamba,
"mandalay": Colours.mandalay,
"mandy": Colours.mandy,
"mandysPink": Colours.mandysPink,
"manhattan": Colours.manhattan,
"mantis": Colours.mantis,
"mantle": Colours.mantle,
"manz": Colours.manz,
"mardiGras": Colours.mardiGras,
"marigold": Colours.marigold,
"mariner": Colours.mariner,
"marlin": Colours.marlin,
"maroon": Colours.maroon,
"marshland": Colours.marshland,
"martini": Colours.martini,
"martinique": Colours.martinique,
"marzipan": Colours.marzipan,
"masala": Colours.masala,
"mash": Colours.mash,
"matisse": Colours.matisse,
"matrix": Colours.matrix,
"matterhorn": Colours.matterhorn,
"maverick": Colours.maverick,
"mckenzie": Colours.mckenzie,
"melanie": Colours.melanie,
"melanzane": Colours.melanzane,
"melrose": Colours.melrose,
"meranti": Colours.meranti,
"mercury": Colours.mercury,
"merino": Colours.merino,
"merlin": Colours.merlin,
"merlot": Colours.merlot,
"metallicBronze": Colours.metallicBronze,
"metallicCopper": Colours.metallicCopper,
"meteor": Colours.meteor,
"meteorite": Colours.meteorite,
"mexicanRed": Colours.mexicanRed,
"midGrey": Colours.midGrey,
"midnight": Colours.midnight,
"midnightExpress": Colours.midnightExpress,
"midnightMoss": Colours.midnightMoss,
"mikado": Colours.mikado,
"milan": Colours.milan,
"milanoRed": Colours.milanoRed,
"milkPunch": Colours.milkPunch,
"milkWhite": Colours.milkWhite,
"millbrook": Colours.millbrook,
"mimosa": Colours.mimosa,
"mindaro": Colours.mindaro,
"mineShaft": Colours.mineShaft,
"mineralGreen": Colours.mineralGreen,
"ming": Colours.ming,
"minsk": Colours.minsk,
"mintJulep": Colours.mintJulep,
"mintTulip": Colours.mintTulip,
"mirage": Colours.mirage,
"mischka": Colours.mischka,
"mistGrey": Colours.mistGrey,
"mobster": Colours.mobster,
"moccaccino": Colours.moccaccino,
"mocha": Colours.mocha,
"mojo": Colours.mojo,
"monaLisa": Colours.monaLisa,
"monarch": Colours.monarch,
"mondo": Colours.mondo,
"mongoose": Colours.mongoose,
"monsoon": Colours.monsoon,
"montana": Colours.montana,
"monteCarlo": Colours.monteCarlo,
"monza": Colours.monza,
"moodyBlue": Colours.moodyBlue,
"moonGlow": Colours.moonGlow,
"moonMist": Colours.moonMist,
"moonRaker": Colours.moonRaker,
"moonYellow": Colours.moonYellow,
"morningGlory": Colours.morningGlory,
"moroccoBrown": Colours.moroccoBrown,
"mortar": Colours.mortar,
"mosaic": Colours.mosaic,
"mosque": Colours.mosque,
"mountainMist": Colours.mountainMist,
"muddyWaters": Colours.muddyWaters,
"muesli": Colours.muesli,
"mulberry": Colours.mulberry,
"muleFawn": Colours.muleFawn,
"mulledWine": Colours.mulledWine,
"mustard": Colours.mustard,
"myPink": Colours.myPink,
"mySin": Colours.mySin,
"mystic": Colours.mystic,
"nandor": Colours.nandor,
"napa": Colours.napa,
"narvik": Colours.narvik,
"natural": Colours.natural,
"nebula": Colours.nebula,
"negroni": Colours.negroni,
"nepal": Colours.nepal,
"neptune": Colours.neptune,
"nero": Colours.nero,
"neutralGreen": Colours.neutralGreen,
"nevada": Colours.nevada,
"newAmber": Colours.newAmber,
"newOrleans": Colours.newOrleans,
"newYorkPink": Colours.newYorkPink,
"niagara": Colours.niagara,
"nightRider": Colours.nightRider,
"nightShadz": Colours.nightShadz,
"nightclub": Colours.nightclub,
"nileBlue": Colours.nileBlue,
"nobel": Colours.nobel,
"nomad": Colours.nomad,
"nordic": Colours.nordic,
"norway": Colours.norway,
"nugget": Colours.nugget,
"nutmeg": Colours.nutmeg,
"nutmegWoodFinish": Colours.nutmegWoodFinish,
"oasis": Colours.oasis,
"observatory": Colours.observatory,
"oceanGreen": Colours.oceanGreen,
"offGreen": Colours.offGreen,
"offYellow": Colours.offYellow,
"oil": Colours.oil,
"oiledCedar": Colours.oiledCedar,
"oldBrick": Colours.oldBrick,
"oldCopper": Colours.oldCopper,
"oliveGreen": Colours.oliveGreen,
"oliveHaze": Colours.oliveHaze,
"olivetone": Colours.olivetone,
"onahau": Colours.onahau,
"onion": Colours.onion,
"opal": Colours.opal,
"opium": Colours.opium,
"oracle": Colours.oracle,
"orangeRoughy": Colours.orangeRoughy,
"orangeWhite": Colours.orangeWhite,
"orchidWhite": Colours.orchidWhite,
"oregon": Colours.oregon,
"orient": Colours.orient,
"orientalPink": Colours.orientalPink,
"orinoco": Colours.orinoco,
"osloGrey": Colours.osloGrey,
"ottoman": Colours.ottoman,
"outerSpace": Colours.outerSpace,
"oxfordBlue": Colours.oxfordBlue,
"oxley": Colours.oxley,
"oysterBay": Colours.oysterBay,
"oysterPink": Colours.oysterPink,
"paarl": Colours.paarl,
"pablo": Colours.pablo,
"pacifika": Colours.pacifika,
"paco": Colours.paco,
"padua": Colours.padua,
"paleLeaf": Colours.paleLeaf,
"paleOyster": Colours.paleOyster,
"palePrim": Colours.palePrim,
"paleRose": Colours.paleRose,
"paleSky": Colours.paleSky,
"paleSlate": Colours.paleSlate,
"palmGreen": Colours.palmGreen,
"palmLeaf": Colours.palmLeaf,
"pampas": Colours.pampas,
"panache": Colours.panache,
"pancho": Colours.pancho,
"panda": Colours.panda,
"paprika": Colours.paprika,
"paradiso": Colours.paradiso,
"parchment": Colours.parchment,
"parisDaisy": Colours.parisDaisy,
"parisM": Colours.parisM,
"parisWhite": Colours.parisWhite,
"parsley": Colours.parsley,
"patina": Colours.patina,
"pattensBlue": Colours.pattensBlue,
"paua": Colours.paua,
"pavlova": Colours.pavlova,
"peaSoup": Colours.peaSoup,
"peach": Colours.peach,
"peachSchnapps": Colours.peachSchnapps,
"peanut": Colours.peanut,
"pearlBush": Colours.pearlBush,
"pearlLusta": Colours.pearlLusta,
"peat": Colours.peat,
"pelorous": Colours.pelorous,
"peppermint": Colours.peppermint,
"perano": Colours.perano,
"perfume": Colours.perfume,
"periglacialBlue": Colours.periglacialBlue,
"persianPlum": Colours.persianPlum,
"persianRed": Colours.persianRed,
"persimmon": Colours.persimmon,
"peruTan": Colours.peruTan,
"pesto": Colours.pesto,
"petiteOrchid": Colours.petiteOrchid,
"pewter": Colours.pewter,
"pharlap": Colours.pharlap,
"picasso": Colours.picasso,
"pickledAspen": Colours.pickledAspen,
"pickledBean": Colours.pickledBean,
"pickledBluewood": Colours.pickledBluewood,
"pictonBlue": Colours.pictonBlue,
"pigeonPost": Colours.pigeonPost,
"pineCone": Colours.pineCone,
"pineGlade": Colours.pineGlade,
"pineTree": Colours.pineTree,
"pinkFlare": Colours.pinkFlare,
"pinkLace": Colours.pinkLace,
"pinkLady": Colours.pinkLady,
"pinkSwan": Colours.pinkSwan,
"piper": Colours.piper,
"pipi": Colours.pipi,
"pippin": Colours.pippin,
"pirateGold": Colours.pirateGold,
"pistachio": Colours.pistachio,
"pixieGreen": Colours.pixieGreen,
"pizazz": Colours.pizazz,
"pizza": Colours.pizza,
"plantation": Colours.plantation,
"planter": Colours.planter,
"plum": Colours.plum,
"pohutukawa": Colours.pohutukawa,
"polar": Colours.polar,
"poloBlue": Colours.poloBlue,
"pompadour": Colours.pompadour,
"porcelain": Colours.porcelain,
"porsche": Colours.porsche,
"portGore": Colours.portGore,
"portafino": Colours.portafino,
"portage": Colours.portage,
"portica": Colours.portica,
"potPourri": Colours.potPourri,
"pottersClay": Colours.pottersClay,
"powderBlue": Colours.powderBlue,
"prairieSand": Colours.prairieSand,
"prelude": Colours.prelude,
"prim": Colours.prim,
"primrose": Colours.primrose,
"promenade": Colours.promenade,
"provincialPink": Colours.provincialPink,
"prussianBlue": Colours.prussianBlue,
"pueblo": Colours.pueblo,
"puertoRico": Colours.puertoRico,
"pumice": Colours.pumice,
"pumpkin": Colours.pumpkin,
"punch": Colours.punch,
"punga": Colours.punga,
"putty": Colours.putty,
"quarterPearlLusta": Colours.quarterPearlLusta,
"quarterSpanishWhite": Colours.quarterSpanishWhite,
"quicksand": Colours.quicksand,
"quillGrey": Colours.quillGrey,
"quincy": Colours.quincy,
"racingGreen": Colours.racingGreen,
"raffia": Colours.raffia,
"rainForest": Colours.rainForest,
"raincloud": Colours.raincloud,
"rainee": Colours.rainee,
"rajah": Colours.rajah,
"rangitoto": Colours.rangitoto,
"rangoonGreen": Colours.rangoonGreen,
"raven": Colours.raven,
"rebel": Colours.rebel,
"redBeech": Colours.redBeech,
"redBerry": Colours.redBerry,
"redDamask": Colours.redDamask,
"redDevil": Colours.redDevil,
"redOxide": Colours.redOxide,
"redRobin": Colours.redRobin,
"redStage": Colours.redStage,
"redwood": Colours.redwood,
"reef": Colours.reef,
"reefGold": Colours.reefGold,
"regalBlue": Colours.regalBlue,
"regentGrey": Colours.regentGrey,
"regentStBlue": Colours.regentStBlue,
"remy": Colours.remy,
"renoSand": Colours.renoSand,
"resolutionBlue": Colours.resolutionBlue,
"revolver": Colours.revolver,
"rhino": Colours.rhino,
"ribbon": Colours.ribbon,
"riceCake": Colours.riceCake,
"riceFlower": Colours.riceFlower,
"richGold": Colours.richGold,
"rioGrande": Colours.rioGrande,
"riptide": Colours.riptide,
"riverBed": Colours.riverBed,
"robRoy": Colours.robRoy,
"robinsEggBlue": Colours.robinsEggBlue,
"rock": Colours.rock,
"rockBlue": Colours.rockBlue,
"rockSalt": Colours.rockSalt,
"rockSpray": Colours.rockSpray,
"rodeoDust": Colours.rodeoDust,
"rollingStone": Colours.rollingStone,
"roman": Colours.roman,
"romanCoffee": Colours.romanCoffee,
"romance": Colours.romance,
"romantic": Colours.romantic,
"ronchi": Colours.ronchi,
"roofTerracotta": Colours.roofTerracotta,
"rope": Colours.rope,
"rose": Colours.rose,
"roseBud": Colours.roseBud,
"roseBudCherry": Colours.roseBudCherry,
"roseofSharon": Colours.roseofSharon,
"roseWhite": Colours.roseWhite,
"rosewood": Colours.rosewood,
"roti": Colours.roti,
"rouge": Colours.rouge,
"royalHeath": Colours.royalHeath,
"rum": Colours.rum,
"rumSwizzle": Colours.rumSwizzle,
"russett": Colours.russett,
"rusticRed": Colours.rusticRed,
"rustyNail": Colours.rustyNail,
"saddle": Colours.saddle,
"saddleBrown": Colours.saddleBrown,
"saffron": Colours.saffron,
"sage": Colours.sage,
"sahara": Colours.sahara,
"sail": Colours.sail,
"salem": Colours.salem,
"salomie": Colours.salomie,
"saltBox": Colours.saltBox,
"saltpan": Colours.saltpan,
"sambuca": Colours.sambuca,
"sanFelix": Colours.sanFelix,
"sanJuan": Colours.sanJuan,
"sanMarino": Colours.sanMarino,
"sandDune": Colours.sandDune,
"sandal": Colours.sandal,
"sandrift": Colours.sandrift,
"sandstone": Colours.sandstone,
"sandwisp": Colours.sandwisp,
"sandyBeach": Colours.sandyBeach,
"sangria": Colours.sangria,
"sanguineBrown": Colours.sanguineBrown,
"santaFe": Colours.santaFe,
"santasGrey": Colours.santasGrey,
"sapling": Colours.sapling,
"sapphire": Colours.sapphire,
"saratoga": Colours.saratoga,
"sauvignon": Colours.sauvignon,
"sazerac": Colours.sazerac,
"scampi": Colours.scampi,
"scandal": Colours.scandal,
"scarletGum": Colours.scarletGum,
"scarlett": Colours.scarlett,
"scarpaFlow": Colours.scarpaFlow,
"schist": Colours.schist,
"schooner": Colours.schooner,
"scooter": Colours.scooter,
"scorpion": Colours.scorpion,
"scotchMist": Colours.scotchMist,
"scrub": Colours.scrub,
"seaBuckthorn": Colours.seaBuckthorn,
"seaFog": Colours.seaFog,
"seaGreen": Colours.seaGreen,
"seaMist": Colours.seaMist,
"seaNymph": Colours.seaNymph,
"seaPink": Colours.seaPink,
"seagull": Colours.seagull,
"seance": Colours.seance,
"seashell": Colours.seashell,
"seaweed": Colours.seaweed,
"selago": Colours.selago,
"sepia": Colours.sepia,
"serenade": Colours.serenade,
"shadowGreen": Colours.shadowGreen,
"shadyLady": Colours.shadyLady,
"shakespeare": Colours.shakespeare,
"shalimar": Colours.shalimar,
"shark": Colours.shark,
"sherpaBlue": Colours.sherpaBlue,
"sherwoodGreen": Colours.sherwoodGreen,
"shilo": Colours.shilo,
"shingleFawn": Colours.shingleFawn,
"shipCove": Colours.shipCove,
"shipGrey": Colours.shipGrey,
"shiraz": Colours.shiraz,
"shocking": Colours.shocking,
"shuttleGrey": Colours.shuttleGrey,
"siam": Colours.siam,
"sidecar": Colours.sidecar,
"silk": Colours.silk,
"silverChalice": Colours.silverChalice,
"silverSand": Colours.silverSand,
"silverTree": Colours.silverTree,
"sinbad": Colours.sinbad,
"siren": Colours.siren,
"sirocco": Colours.sirocco,
"sisal": Colours.sisal,
"skeptic": Colours.skeptic,
"slugger": Colours.slugger,
"smaltBlue": Colours.smaltBlue,
"smokeTree": Colours.smokeTree,
"smokeyAsh": Colours.smokeyAsh,
"smoky": Colours.smoky,
"snowDrift": Colours.snowDrift,
"snowFlurry": Colours.snowFlurry,
"snowyMint": Colours.snowyMint,
"snuff": Colours.snuff,
"soapstone": Colours.soapstone,
"softAmber": Colours.softAmber,
"softPeach": Colours.softPeach,
"solidPink": Colours.solidPink,
"solitaire": Colours.solitaire,
"solitude": Colours.solitude,
"sorbus": Colours.sorbus,
"sorrellBrown": Colours.sorrellBrown,
"sourDough": Colours.sourDough,
"soyaBean": Colours.soyaBean,
"spaceShuttle": Colours.spaceShuttle,
"spanishGreen": Colours.spanishGreen,
"spanishWhite": Colours.spanishWhite,
"spectra": Colours.spectra,
"spice": Colours.spice,
"spicyMix": Colours.spicyMix,
"spicyPink": Colours.spicyPink,
"spindle": Colours.spindle,
"splash": Colours.splash,
"spray": Colours.spray,
"springGreen": Colours.springGreen,
"springRain": Colours.springRain,
"springSun": Colours.springSun,
"springWood": Colours.springWood,
"sprout": Colours.sprout,
"spunPearl": Colours.spunPearl,
"squirrel": Colours.squirrel,
"stTropaz": Colours.stTropaz,
"stack": Colours.stack,
"starDust": Colours.starDust,
"starkWhite": Colours.starkWhite,
"starship": Colours.starship,
"steelGrey": Colours.steelGrey,
"stiletto": Colours.stiletto,
"stinger": Colours.stinger,
"stonewall": Colours.stonewall,
"stormDust": Colours.stormDust,
"stormGrey": Colours.stormGrey,
"stratos": Colours.stratos,
"straw": Colours.straw,
"strikemaster": Colours.strikemaster,
"stromboli": Colours.stromboli,
"studio": Colours.studio,
"submarine": Colours.submarine,
"sugarCane": Colours.sugarCane,
"sulu": Colours.sulu,
"summerGreen": Colours.summerGreen,
"sun": Colours.sun,
"sundance": Colours.sundance,
"sundown": Colours.sundown,
"sunflower": Colours.sunflower,
"sunglo": Colours.sunglo,
"sunset": Colours.sunset,
"sunshade": Colours.sunshade,
"supernova": Colours.supernova,
"surf": Colours.surf,
"surfCrest": Colours.surfCrest,
"surfieGreen": Colours.surfieGreen,
"sushi": Colours.sushi,
"suvaGrey": Colours.suvaGrey,
"swamp": Colours.swamp,
"swansDown": Colours.swansDown,
"sweetCorn": Colours.sweetCorn,
"sweetPink": Colours.sweetPink,
"swirl": Colours.swirl,
"swissCoffee": Colours.swissCoffee,
"sycamore": Colours.sycamore,
"tabasco": Colours.tabasco,
"tacao": Colours.tacao,
"tacha": Colours.tacha,
"tahitiGold": Colours.tahitiGold,
"tahunaSands": Colours.tahunaSands,
"tallPoppy": Colours.tallPoppy,
"tallow": Colours.tallow,
"tamarillo": Colours.tamarillo,
"tamarind": Colours.tamarind,
"tana": Colours.tana,
"tangaroa": Colours.tangaroa,
"tangerine": Colours.tangerine,
"tango": Colours.tango,
"tapa": Colours.tapa,
"tapestry": Colours.tapestry,
"tara": Colours.tara,
"tarawera": Colours.tarawera,
"tasman": Colours.tasman,
"taupeGrey": Colours.taupeGrey,
"tawnyPort": Colours.tawnyPort,
"taxBreak": Colours.taxBreak,
"tePapaGreen": Colours.tePapaGreen,
"tea": Colours.tea,
"teak": Colours.teak,
"teakWoodFinish": Colours.teakWoodFinish,
"tealBlue": Colours.tealBlue,
"temptress": Colours.temptress,
"tequila": Colours.tequila,
"texas": Colours.texas,
"texasRose": Colours.texasRose,
"thatch": Colours.thatch,
"thatchGreen": Colours.thatchGreen,
"thistle": Colours.thistle,
"thunder": Colours.thunder,
"thunderbird": Colours.thunderbird,
"tiaMaria": Colours.tiaMaria,
"tiara": Colours.tiara,
"tiber": Colours.tiber,
"tidal": Colours.tidal,
"tide": Colours.tide,
"timberGreen": Colours.timberGreen,
"titanWhite": Colours.titanWhite,
"toast": Colours.toast,
"tobaccoBrown": Colours.tobaccoBrown,
"tobago": Colours.tobago,
"toledo": Colours.toledo,
"tolopea": Colours.tolopea,
"tomThumb": Colours.tomThumb,
"tonysPink": Colours.tonysPink,
"topaz": Colours.topaz,
"toreaBay": Colours.toreaBay,
"toryBlue": Colours.toryBlue,
"tosca": Colours.tosca,
"totemPole": Colours.totemPole,
"touchWood": Colours.touchWood,
"towerGrey": Colours.towerGrey,
"tradewind": Colours.tradewind,
"tranquil": Colours.tranquil,
"travertine": Colours.travertine,
"treePoppy": Colours.treePoppy,
"treehouse": Colours.treehouse,
"trendyGreen": Colours.trendyGreen,
"trendyPink": Colours.trendyPink,
"trinidad": Colours.trinidad,
"tropicalBlue": Colours.tropicalBlue,
"trout": Colours.trout,
"trueV": Colours.trueV,
"tuatara": Colours.tuatara,
"tuftBush": Colours.tuftBush,
"tulipTree": Colours.tulipTree,
"tumbleweed": Colours.tumbleweed,
"tuna": Colours.tuna,
"tundora": Colours.tundora,
"turbo": Colours.turbo,
"turkishRose": Colours.turkishRose,
"turmeric": Colours.turmeric,
"turtleGreen": Colours.turtleGreen,
"tuscany": Colours.tuscany,
"tusk": Colours.tusk,
"tussock": Colours.tussock,
"tutu": Colours.tutu,
"twilight": Colours.twilight,
"twilightBlue": Colours.twilightBlue,
"twine": Colours.twine,
"valencia": Colours.valencia,
"valentino": Colours.valentino,
"valhalla": Colours.valhalla,
"vanCleef": Colours.vanCleef,
"vanilla": Colours.vanilla,
"vanillaIce": Colours.vanillaIce,
"varden": Colours.varden,
"venetianRed": Colours.venetianRed,
"veniceBlue": Colours.veniceBlue,
"venus": Colours.venus,
"verdigris": Colours.verdigris,
"verdunGreen": Colours.verdunGreen,
"vesuvius": Colours.vesuvius,
"victoria": Colours.victoria,
"vidaLoca": Colours.vidaLoca,
"viking": Colours.viking,
"vinRouge": Colours.vinRouge,
"viola": Colours.viola,
"violentViolet": Colours.violentViolet,
"violet": Colours.violet,
"viridianGreen": Colours.viridianGreen,
"visVis": Colours.visVis,
"vistaBlue": Colours.vistaBlue,
"vistaWhite": Colours.vistaWhite,
"volcano": Colours.volcano,
"voodoo": Colours.voodoo,
"vulcan": Colours.vulcan,
"wafer": Colours.wafer,
"waikawaGrey": Colours.waikawaGrey,
"waiouru": Colours.waiouru,
"walnut": Colours.walnut,
"wanWhite": Colours.wanWhite,
"wasabi": Colours.wasabi,
"waterLeaf": Colours.waterLeaf,
"watercourse": Colours.watercourse,
"waterloo": Colours.waterloo,
"wattle": Colours.wattle,
"watusi": Colours.watusi,
"waxFlower": Colours.waxFlower,
"wePeep": Colours.wePeep,
"wedgewood": Colours.wedgewood,
"wellRead": Colours.wellRead,
"westCoast": Colours.westCoast,
"westSide": Colours.westSide,
"westar": Colours.westar,
"westernRed": Colours.westernRed,
"wewak": Colours.wewak,
"wheatfield": Colours.wheatfield,
"whiskey": Colours.whiskey,
"whiskeySour": Colours.whiskeySour,
"whisper": Colours.whisper,
"whiteIce": Colours.whiteIce,
"whiteLilac": Colours.whiteLilac,
"whiteLinen": Colours.whiteLinen,
"whiteNectar": Colours.whiteNectar,
"whitePointer": Colours.whitePointer,
"whiteRock": Colours.whiteRock,
"wildRice": Colours.wildRice,
"wildSand": Colours.wildSand,
"wildWillow": Colours.wildWillow,
"william": Colours.william,
"willowBrook": Colours.willowBrook,
"willowGrove": Colours.willowGrove,
"windsor": Colours.windsor,
"wineBerry": Colours.wineBerry,
"winterHazel": Colours.winterHazel,
"wispPink": Colours.wispPink,
"wisteria": Colours.wisteria,
"wistful": Colours.wistful,
"witchHaze": Colours.witchHaze,
"woodBark": Colours.woodBark,
"woodburn": Colours.woodburn,
"woodland": Colours.woodland,
"woodrush": Colours.woodrush,
"woodsmoke": Colours.woodsmoke,
"woodyBay": Colours.woodyBay,
"woodyBrown": Colours.woodyBrown,
"xanadu": Colours.xanadu,
"yellowMetal": Colours.yellowMetal,
"yellowSea": Colours.yellowSea,
"yourPink": Colours.yourPink,
"yukonGold": Colours.yukonGold,
"yuma": Colours.yuma,
"zambezi": Colours.zambezi,
"zanah": Colours.zanah,
"zest": Colours.zest,
"zeus": Colours.zeus,
"ziggurat": Colours.ziggurat,
"zircon": Colours.zircon,
"zombie": Colours.zombie,
"zorba": Colours.zorba,
"zuccini": Colours.zuccini,
"zumthor": Colours.zumthor,
"zydeco": Colours.zydeco,
]; return _colours; }

}
